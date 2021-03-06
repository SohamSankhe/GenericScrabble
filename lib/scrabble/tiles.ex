defmodule Scrabble.Tiles do

  # Tiles
  # freq table = letter vs count
  # points table = letter vs points
  # tilesList = list of all remaining letters (easy to shuffle and splice at
  # end)
  # get tiles and put tiles method

  # x = freq ; Enum.map(1..x, fn _x -> letter end)

  #Enum.reduce(mapp, [], fn {k, v}, acc -> acc ++ appLst.(k,v) end)
  #appLst= fn (k,v) -> Enum.map(1..v, fn _x -> k end) end

  @frequencyTable %{"A" => 9, "B" => 2,"C" => 2, "D" => 4,"E" => 12, "F" => 2,
                    "G" => 3, "H" => 2,"I" => 9, "J" => 1,"K" => 1, "L" => 4,
                    "M" => 2, "N" => 6,"O" => 8, "P" => 2,"Q" => 1, "R" => 6,
                    "S" => 4, "T" => 6,"U" => 4, "V" => 2,"W" => 2, "X" => 1,
                    "Y" => 2, "Z" => 1}

  @pointsTable %{"A" => 1, "B" => 3,"C" => 3, "D" => 2,"E" => 1, "F" => 4,
                  "G" => 2, "H" => 4,"I" => 1, "J" => 8,"K" => 5, "L" => 1,
                  "M" => 3, "N" => 1,"O" => 1, "P" => 3,"Q" => 10, "R" => 1,
                  "S" => 1, "T" => 1,"U" => 1, "V" => 4,"W" => 4, "X" => 8,
                  "Y" => 4, "Z" => 10}

  # return a list of 100 letters depending on frequencyTable
  def generateTileList() do
    expandToList = fn (k,v) -> Enum.map(1..v, fn _x -> k end) end
    Enum.reduce(@frequencyTable, [], fn {k, v}, acc ->
      acc ++ expandToList.(k,v) end)
  end

  # get 'count' number of tiles - use to assign/refill rack
  # return tuple of remaining tiles and randomly picked tiles
  def getTiles(tiles, count) do
    cond do
      length(tiles) == 0 ->
        {[],[]}
      # if enough tiles are not available, return all
      length(tiles) < count ->
        {[],Enum.shuffle(tiles)}
      true ->
        shuffledList = Enum.shuffle(tiles)
        Enum.split(shuffledList, length(tiles) - count)
    end
  end

  def putTiles(tiles, toPut) do
    newTileList = tiles ++ toPut
  end

  def getPointsForLetter(letter) do
    @pointsTable[letter]
  end

end
