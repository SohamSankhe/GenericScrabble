defmodule Scrabble.Play do
  alias Scrabble.Grid
  alias Scrabble.ValidatePlay
  alias Scrabble.Words
  alias Scrabble.Tiles
  alias Scrabble.Score

  def processPlay(game, board, boardIndPlayed, rackIndPlayed) do
    # 'board' arg contains board with the latest play on it

	  # convert client's single index input values to x,y coord system
    updatedBoard = convertGridCoords(board)
    brdIndexes = Enum.map(boardIndPlayed, fn x -> convertToXY(getInt(x)) end)
    # Validate input
    {valStatus, valMsg} = ValidatePlay.isPlayValid(game, updatedBoard, brdIndexes)


    if valStatus == :ok do
    # Identify words updated/created
      wordCoords = Words.findWords(updatedBoard, brdIndexes)

      # check correctness of words
      {_, words, incorrectWords} = Words.checkWords(updatedBoard, wordCoords)
      cond do
        length(incorrectWords) > 0 ->

          handleIncorrectWordPlay(game, incorrectWords)
        true ->
          handleCorrectWordPlay(game, updatedBoard, rackIndPlayed, brdIndexes, words, wordCoords)

      end
    else
      game = Map.put(game, :message, valMsg)
      game
    end
  end

  def processSwap(game, currentRackIndex) do
    currentRackIndex = (if (currentRackIndex == nil), do: -1, else: getInt(currentRackIndex))
    whosTurn = check_whosturn(game)
    if (currentRackIndex < 0  or currentRackIndex > 6) do
      game
    else
      # change rack of the player
      playerRack = (if (whosTurn == "player2"), do: game.rack1, else: game.rack2)
      tileToSwap = Enum.at(playerRack, currentRackIndex)
      newTileList = Tiles.putTiles(game.tiles, [tileToSwap])
      {newTileList, newTile} = Tiles.getTiles(newTileList, 1)
      playerRack = List.delete_at(playerRack, currentRackIndex)
      playerRack = List.insert_at(playerRack, currentRackIndex, hd(newTile))

      game = Map.put(game, :whosturn, whosTurn)
      game = Map.put(game,
        :rack1, (if (whosTurn == "player2"), do: playerRack, else: game.rack1))
      game = Map.put(game,
        :rack2, (if (whosTurn == "player1"), do: playerRack, else: game.rack2))
      game = Map.put(game, :tiles, newTileList)
      game = Map.put(game, :message, "")
      game
    end
  end

  def processPass(game) do
    IO.puts("Player chooses to pass his turn")
    whosTurn = check_whosturn(game)
    plyrName = (if (whosTurn == "player2"), do: "Player1", else: "Player2")
    msg = "#{plyrName} chose to pass"

    game = Map.put(game, :whosturn, whosTurn)
    game = Map.put(game, :message, msg)
    game
  end

  def processForfeit(game) do
    IO.puts("Player chooses to give up")
    whosTurn = check_whosturn(game)
    plyrName = (if (whosTurn == "player2"), do: "Player1", else: "Player2")
    winner = (if (whosTurn == "player2"), do: "Player2", else: "Player1")
    msg = "#{plyrName} chose to forfeit. #{winner} wins!"

    game = Map.put(game, :whosturn, whosTurn)
    game = Map.put(game, :message, msg)
    game = Map.put(game, :isActive, false)
    game
  end


  def handleCorrectWordPlay(game, updatedBoard, rackIndPlayed, boardIndPlayed,
        words, wordCoords) do


    whosTurn = check_whosturn(game)

    # score game updatedboard boardindplayed wordCoords
    score = Score.calculateScore(game, updatedBoard, boardIndPlayed, wordCoords)
    playerRack = if whosTurn == "player2", do: game.rack1, else: game.rack2

    {remainingTiles, newRack} = updateRack(game, playerRack, rackIndPlayed)

    game = Map.put(game, :whosturn, whosTurn)

    game = Map.put(game,
      :rack1, (if (whosTurn == "player2"), do: newRack, else: game.rack1))
    game = Map.put(game,
      :score1,(if (whosTurn == "player2"), do: game.score1 + score, else: game.score1))
    game = Map.put(game,
      :lastScore1,(if (whosTurn == "player2"), do: score, else: 0))

    game = Map.put(game,
      :rack2, (if (whosTurn == "player1"), do: newRack, else: game.rack2))
    game = Map.put(game,
      :score2,(if (whosTurn == "player1"), do: game.score2 + score, else: game.score2))
    game = Map.put(game,
      :lastScore2,(if (whosTurn == "player1"), do: score, else: 0))

    game = Map.put(game, :tiles, remainingTiles)
    game = Map.put(game, :board, updatedBoard)
    game = Map.put(game, :words, words)
    #game = Map.put(game, :message, "")

    game = cond do
      length(newRack) == 0 ->
        msg = cond do
          game.score1 > game.score2 -> "Player 1 wins"
          game.score1 < game.score2 -> "Player 2 wins"
          true -> "It is a tie"
        end
        game = Map.put(game, :message, msg)
        game = Map.put(game, :isActive, false)
      true -> game = Map.put(game, :message, "")
    end

    game
  end

  def handleIncorrectWordPlay(game, incorrectWords) do
    incorrectWordStr = Enum.reduce(incorrectWords, "", fn y, acc -> "#{acc} #{y}" end)
    msg = "Incorrect word(s): " <> incorrectWordStr
    game = Map.put(game, :message, msg)
    game
  end

  # a player's rack and the indexes of tiles he has used
  # replace those tiles in the rack from tiles.ex
  def updateRack(game, rack, rackIndPlayed) do
    rackIndPlayedInt = Enum.reduce(rackIndPlayed, [], fn x, acc ->
      acc ++ [getInt(x)] end)
    # remove played indexes
    rackWithIndexes = Enum.with_index(rack)
    updatedRack = Enum.reduce(rackWithIndexes, [], fn {val, index}, acc ->
      if !Enum.member?(rackIndPlayedInt, index) do
          acc ++ [val]
      else
          acc
      end
    end)

    tilesReq = 7 - length(updatedRack)
    {tileList, newRack} = Tiles.getTiles(game.tiles, tilesReq)
    {tileList, newRack ++ updatedRack}
  end

  # convert clients single index grid in x,y coord system
  def convertGridCoords(board) do
    indexedBoard = Enum.with_index(board)
    Enum.reduce(indexedBoard, %{}, fn {value, index}, acc ->
        {xCoord, yCoord} = convertToXY(index)
        bonusVal = Grid.getBonus(xCoord, yCoord)
        Map.put(acc, {xCoord, yCoord}, [letter: value, bonus: bonusVal])
      end)
  end

  # x = num % 15 and y = num / 15
  def convertToXY(ind) do
    mod = rem(ind, 15)
    xCoord = mod
    yCoord = div((ind - mod),15)
    #{xCoord, yCoord}
    {yCoord, xCoord}
  end


  def getInt(str) do
    {intVal, ""} = Integer.parse(str)
    intVal
  end

  def check_whosturn(game) do
    if game.whosturn == "player1" do
      "player2"
    else
      "player1"
    end
  end


end
