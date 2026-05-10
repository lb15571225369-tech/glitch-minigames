-- Glitch Notiforcations System
-- Copyright (C) 2024 Glitch
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <https://www.gnu.org/licenses/>.

local isNotificationDisplayed = false
local activeNotifications = {}
local nextId = 1
local nextBoxId = 1

local testNotis = false -- Set to true to enable test notifications

function ShowNotification(title, message, duration, color, noAnimation)
    if not title or not message then return end
    duration = duration or 5000
    color = color or "#4a90e2"
    noAnimation = noAnimation or false

    local existingId, existingBoxId = nil, nil
    for id, notif in pairs(activeNotifications) do
        if notif.mainTitle == title then
            existingId = id
            break
        end
    end

    if existingId then
        return AddBoxToNotification(existingId, title, message, color, noAnimation)
    end

    local id = nextId
    nextId = nextId + 1

    local boxId = nextBoxId
    nextBoxId = nextBoxId + 1

    activeNotifications[id] = {
        boxes = {
            [boxId] = {
                title = title,
                message = message,
                color = color
            }
        },
        mainTitle = title
    }

    SendNUIMessage({
        type = "showNotification",
        id = id,
        boxId = boxId,
        title = title,
        message = message,
        duration = duration,
        color = color,
        noAnimation = noAnimation
    })

    if duration > 0 then
        Citizen.SetTimeout(duration, function()
            if activeNotifications[id] then
                RemoveNotification(id)
            end
        end)
    end

    return id, boxId
end

function AddBoxToNotification(notificationId, title, message, color, noAnimation)
    if not notificationId or not activeNotifications[notificationId] then 
        return ShowNotification(title, message, 0, color, noAnimation)
    end

    color = color or "#4a90e2"
    noAnimation = noAnimation or false

    local boxId = nextBoxId
    nextBoxId = nextBoxId + 1

    activeNotifications[notificationId].boxes[boxId] = {
        title = title,
        message = message,
        color = color
    }

    SendNUIMessage({
        type = "addBoxToNotification",
        id = notificationId,
        boxId = boxId,
        title = title,
        message = message,
        color = color,
        noAnimation = noAnimation
    })

    return notificationId, boxId
end

function RemoveBoxFromNotification(notificationId, boxId)
    if not notificationId or not activeNotifications[notificationId] or
       not boxId or not activeNotifications[notificationId].boxes[boxId] then
        return false
    end

    activeNotifications[notificationId].boxes[boxId] = nil

    SendNUIMessage({
        type = "removeBoxFromNotification",
        id = notificationId,
        boxId = boxId
    })

    local boxCount = 0
    for _ in pairs(activeNotifications[notificationId].boxes) do
        boxCount = boxCount + 1
    end

    if boxCount == 0 then
        activeNotifications[notificationId] = nil
    end

    return true
end

function RemoveNotification(id)
    if not id or not activeNotifications[id] then return false end

    SendNUIMessage({
        type = "removeNotification",
        id = id
    })

    activeNotifications[id] = nil
    return true
end

function UpdateBoxContent(notificationId, boxId, newMessage, newTitle, newColor)
    if not notificationId or not activeNotifications[notificationId] or
       not boxId or not activeNotifications[notificationId].boxes[boxId] then
        return false
    end

    local box = activeNotifications[notificationId].boxes[boxId]

    if newTitle then box.title = newTitle end
    if newMessage then box.message = newMessage end
    if newColor then box.color = newColor end

    SendNUIMessage({
        type = "updateBoxContent",
        id = notificationId,
        boxId = boxId,
        title = newTitle,
        message = newMessage,
        color = newColor,
        noAnimation = true
    })

    return true
end

function ToggleNotification(id, title, message, color)
    if activeNotifications[id] then
        return RemoveNotification(id)
    else
        return ShowNotification(title, message, 0, color)
    end
end

if testNotis then 
    RegisterCommand('testnotify', function(source, args)
        ShowNotification('Diamond Casino & Resort', 'Gain access to the Cameras', 15000)
    end, false)

    RegisterCommand('colornotify', function(source, args)
        local color = args[1] or "#ff4500"
        ShowNotification('Maze Bank', 'Transaction completed', 15000, color)
    end, false)

    RegisterCommand('togglenotify', function(source, args)
        if not _G.testToggleId then
            _G.testToggleId = 9999
        end

        ToggleNotification(_G.testToggleId, 'Toggle Notification', 'This notification can be toggled on/off', "#22bb33")
    end, false)

    RegisterCommand('multibox', function(source, args)
        local notifId, boxId = ShowNotification('Multi-Box Notification', 'This is the first box', 0, "#4a90e2")

        Citizen.SetTimeout(2000, function()
            local _, box2Id = AddBoxToNotification(notifId, 'Second Box', 'This is the second box', "#22bb33")

            Citizen.SetTimeout(2000, function()
                local _, box3Id = AddBoxToNotification(notifId, 'Third Box', 'This is the third box', "#ff4500")

                Citizen.SetTimeout(3000, function()
                    RemoveBoxFromNotification(notifId, box2Id)
                end)
            end)
        end)
    end, false)

    RegisterCommand('updatebox', function(source, args)
        local notifId, boxId = ShowNotification('Timer Example', 'Time remaining: 10 seconds', 0, "#4a90e2")

        local timeLeft = 10
        local timerId = nil

        local function updateTimer()
            timeLeft = timeLeft - 1
            if timeLeft <= 0 then
                UpdateBoxContent(notifId, boxId, 'Time\'s up!')
                if timerId then
                    clearInterval(timerId)
                end
            else
                UpdateBoxContent(notifId, boxId, 'Time remaining: ' .. timeLeft .. ' seconds')
            end
        end

        function setInterval(callback, interval)
            local timer = 0
            local id = GetGameTimer()

            Citizen.CreateThread(function()
                while timer >= 0 do
                    Citizen.Wait(interval)
                    callback()
                end
            end)

            return id
        end

        function clearInterval(id)
            timer = -1
        end

        timerId = setInterval(updateTimer, 1000)
    end, false)
end

exports('ShowNotification', ShowNotification)
exports('AddBoxToNotification', AddBoxToNotification)
exports('RemoveBoxFromNotification', RemoveBoxFromNotification)
exports('RemoveNotification', RemoveNotification)
exports('UpdateBoxContent', UpdateBoxContent)
exports('ToggleNotification', ToggleNotification)