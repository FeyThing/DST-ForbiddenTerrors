local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

-- NOTE (HALF): Snipping this for testing in xenos deeprainforest mod, sorry asgerr lol.

--asgerrr: this one has been sitting in a txt file on my desktop for a long ass time lol
function d_changetile(tile, radius) 
    local center_dist = radius - 1 
    local center_x, center_y = TheWorld.Map:GetTileCoordsAtPoint(ConsoleWorldPosition():Get()) 
    for x = center_x-center_dist, center_x+center_dist, 1 do 
        for y = center_y-center_dist, center_y+center_dist, 1 do
            if tile == "CHARLIE_VINE" then
                TheWorld.components.undertile:SetTileUnderneath(x, y, TheWorld.Map:GetTile(x, y))
            end
            TheWorld.Map:SetTile(x,y,WORLD_TILES[tile])
        end 
    end 
end

function d_gettile() 
    local center_x, center_y = TheWorld.Map:GetTileCoordsAtPoint(ConsoleWorldPosition():Get()) 
    return INVERTED_WORLD_TILES[TheWorld.Map:GetTile(center_x, center_y)]
end
