GLOBAL.setfenv(1, GLOBAL)

AddClientModRPCHandler("Dark Forest", "OnTerraform", function(data)
    local data = DecodeAndUnzipString(data)
    if TheWorld.components.df_localtilewatcher ~= nil then
        TheWorld.components.df_localtilewatcher:OnTerraform(data)
    end
end)