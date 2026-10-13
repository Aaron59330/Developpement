local WeaponsPlayer = {}
local WeaponsPlayer2 = {}
  
local OpenArmePermMenu = function()
  local CoordsZ = GetEntityCoords(PlayerPedId())
  ESX.TriggerServerCallback('ArmePermCoffre:ReceiveWeapon', function(SendResponse)
    WeaponsPlayer = SendResponse.data1
    WeaponsPlayer2 = SendResponse.data2
  end)

  local mainmenu = RageUI.CreateMenu("Armes permanentes", "Que voulez vous faire ?")
  local depositweapon = RageUI.CreateSubMenu(mainmenu, "Déposer armes", "Voici vos armes permanentes")
  local removeweapon = RageUI.CreateSubMenu(mainmenu, "Retirer armes", "Voici vos armes permanentes")

  RageUI.Visible(mainmenu, not RageUI.Visible(mainmenu))

  while mainmenu do 
      Wait(0)
      if #(GetEntityCoords(PlayerPedId()) - CoordsZ) > 5 then 
          ESX.ShowNotification("~r~Information\n~s~Vous vous éloignez de trop.")
          RageUI.CloseAll()
      end
      RageUI.IsVisible(mainmenu, true, true, true, function()
        RageUI.ButtonWithStyle("Déposer des armes", "Vous permet de déposer des armes permanentes", {RightLabel = "→→→"}, true, function(_,_,s)
        end, depositweapon)
        RageUI.ButtonWithStyle("Retirer des armes", "Vous permet de retirer des armes permanentes", {RightLabel = "→→→"}, true, function(_,_,s)
        end, removeweapon)
      end)

      RageUI.IsVisible(depositweapon, true, true, true, function()
        for k, v in ipairs(WeaponsPlayer2) do
          if Config.ArmesPerm[v.name] then
            RageUI.ButtonWithStyle(""..v.label, nil, { RightLabel = "Munition(s) : ~r~x"..v.ammo }, true, function(_,_,s)
              if s then
                local data = {anticheat = true, arme = v, action = "deposit", Ammo = v.ammo, Label = v.label, Name = v.name}
                TriggerServerEvent("ArmePermCoffre:depositarmesperm", data)
                RageUI.CloseAll()
              end
            end)
          else
            RageUI.ButtonWithStyle(""..v.label, "~r~Ceci n'est pas une arme permanente~s~", { RightLabel = "Munition(s) : ~r~x"..v.ammo }, false, function(_,_,s)
            end)
          end
        end
      end, function()
      end)

      RageUI.IsVisible(removeweapon, true, true, true, function()
        if WeaponsPlayer == nil or #WeaponsPlayer == 0 then
          RageUI.Separator("")
          RageUI.Separator("~r~Aucune arme perm dans le coffre~s~")
          RageUI.Separator("")
        else
          for k, v in pairs(WeaponsPlayer) do
            RageUI.ButtonWithStyle(""..v.label, nil, {RightLabel = "~g~Prendre"}, true, function(_,a,s)
              if a then
                if #json.decode(v.armes)["components"] == 0 then
                  components = "Aucun accessoire d'arme"
                else
                  if json.decode(v.armes)["components"] ~= nil then
                    components = "Vous possédez des accessoires sur votre arme."
                  end
                end
                RageUI.Info("Informations :", {"", "Nom de l'arme : ~b~"..v.name.."~s~", "Label de l'arme : ~b~"..v.label.."~s~", "Nombre de balle : ~b~"..v.munitions.."~s~", "Accessoire : ~b~"..(components or "Aucun accessoire d'arme").."~s~"}, {"", "", ""})
              end

              if s then
                local data = {anticheat = true, arme = v, action = "remove", Ammo = v.munitions, Label = v.label, Name = v.name}
                TriggerServerEvent("ArmePermCoffre:depositarmesperm", data)
                RageUI.CloseAll()
              end
            end)
          end
        end
      end, function()
      end)

      if not RageUI.Visible(mainmenu) and not RageUI.Visible(depositweapon) and not RageUI.Visible(removeweapon) then 
        depositweapon = RMenu:DeleteType("depositweapon")
        removeweapon = RMenu:DeleteType("removeweapon")
        mainmenu = RMenu:DeleteType("mainmenu")
      end
  end
end
  
CreateThread(function()
  while true do
    local timer = 200

    for k, v in pairs(ConfigArmesPrem.Marker.Position) do 
        local dist = Vdist2(GetEntityCoords(PlayerPedId()), v.Pose)
        if dist < 20 then
            timer = 0
            DrawGlobalMarker(ConfigArmesPrem.Marker.Type, v.Pose, 0.0, 0.0, 0.0, ConfigArmesPrem.Marker.Rotation.x, ConfigArmesPrem.Marker.Rotation.y, ConfigArmesPrem.Marker.Rotation.z, ConfigArmesPrem.Marker.Size.x, ConfigArmesPrem.Marker.Size.y, ConfigArmesPrem.Marker.Size.z, ConfigArmesPrem.Marker.Color.r , ConfigArmesPrem.Marker.Color.g, ConfigArmesPrem.Marker.Color.b, 255, 0, false, true, 2, false, false, false, false)
        end
        if dist < 3 then 
            ESX.ShowHelpNotification(ConfigArmesPrem.Text)
            if IsControlJustPressed(0, 51) then 
              ESX.PlayerData = ESX.GetPlayerData()
              OpenArmePermMenu()
            end
        end
    end
    Wait(timer)
  end
end)

function CheckPermWeapon()
  return Config.ArmesPerm
end