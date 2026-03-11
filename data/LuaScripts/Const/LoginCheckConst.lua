
LOGIN_CHECK_STEP_RESULT = {
    Continue = 1,
    Stop = 2,
    BackToStart = 3,
    BackToCurrent = 4,
}
























LoginCheckConflictConfigKey = {
    
    BLACK_SCREEN = "blackScreen",
    
    NARRATIVE = "narrative",
    BLOCK_MSG = "blockMsg"
}

LoginCheckConflictCheckFunc = {
    [LoginCheckConflictConfigKey.BLACK_SCREEN] = function()
        return NarrativeUtils.inBlackScreen
    end,
    [LoginCheckConflictConfigKey.NARRATIVE] = function()
        return NarrativeUtils.isInCommonNarrative
    end,
    [LoginCheckConflictConfigKey.BLOCK_MSG] = function()
        return UIManager:IsShow(PanelId.TransparentBlockInput)
    end
}

LOGIN_CHECK_STEP_KEY = {
    ORDER_SETTLE = "OrderSettle",
    MONTHLYPASS_POPUP = "MonthlyPassPopup",
    CHECK_IN = "CheckIn",
    FORCE_SNS = "ForceSns",
    GUIDE = "Guide"
}




LOGIN_CHECK_STEP_CONFIG = {
    { 
        key = LOGIN_CHECK_STEP_KEY.ORDER_SETTLE,
        checkFunction = function(callback)
            
            if not GameInstance.player.mission:IsMissionCompleted("e0m0") then
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
                return
            end
            CashShopUtils.tryShowRemainOrderList(function()
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
            end)
        end,
        interruptConfig = {
            [LoginCheckConflictConfigKey.BLACK_SCREEN] = true,
            [LoginCheckConflictConfigKey.NARRATIVE] = true,
            [LoginCheckConflictConfigKey.BLOCK_MSG] = true
        },
        waitConfig = {
            [LoginCheckConflictConfigKey.BLACK_SCREEN] = true,
            [LoginCheckConflictConfigKey.NARRATIVE] = true,
            [LoginCheckConflictConfigKey.BLOCK_MSG] = true
        }
    },
    { 
        key = LOGIN_CHECK_STEP_KEY.MONTHLYPASS_POPUP,
        checkFunction = function(callback)
            
            if Utils.isInDungeon() then
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
                return
            end
            local needShowTimeStamps = GameInstance.player.monthlyPassSystem:GetNeedShowDailyPopupTimestamps()
            if needShowTimeStamps.Count == 0 then
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
            else
                local needShowTimeStampsTable = {}
                for _, ts in pairs(needShowTimeStamps) do
                    table.insert(needShowTimeStampsTable, ts)
                end
                local ret = PhaseManager:OpenPhaseFast(PhaseId.ShopMonthlyPassPopUp, {
                    ShowTimeStamps = needShowTimeStampsTable,
                    EndCallback = function()
                        callback(LOGIN_CHECK_STEP_RESULT.Continue)
                    end
                })
                if not ret then
                    logger.error("LoginCheck时打开PhaseId.ShopMonthlyPassPopUp失败!")
                    callback(LOGIN_CHECK_STEP_RESULT.Continue)
                end
            end
        end,
        interruptConfig = {
            [LoginCheckConflictConfigKey.BLACK_SCREEN] = true,
            [LoginCheckConflictConfigKey.NARRATIVE] = true,
            [LoginCheckConflictConfigKey.BLOCK_MSG] = true
        },
        waitConfig = {
            [LoginCheckConflictConfigKey.BLACK_SCREEN] = true,
            [LoginCheckConflictConfigKey.NARRATIVE] = true,
            [LoginCheckConflictConfigKey.BLOCK_MSG] = true
        }
    },
    { 
        key = LOGIN_CHECK_STEP_KEY.CHECK_IN,
        checkFunction = function(callback)
            
            if UNITY_EDITOR and BEYOND_DEBUG and CS.Beyond.DebugDefines.disableCheckInLoginCheck then
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
                return
            end
            
            if Utils.isInDungeon() or Utils.isInFocusMode() then
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
                return
            end
            
            if not PhaseManager:IsPhaseUnlocked(PhaseId.CheckInCBT3) then
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
                return
            end
            
            local ids = ActivityUtils.getCheckInId()
            local popupIds = {}
            for i = 1,#ids do
                local id = ids[i]
                local shouldPopup = id and ActivityUtils.shouldPopup(id)
                if shouldPopup then
                    table.insert(popupIds,id)
                end
            end

            
            if #popupIds > 0 then
                local success = PhaseManager:OpenPhaseFast(PhaseId.CheckInCBT3, {
                    closeCallback = function()
                        callback(LOGIN_CHECK_STEP_RESULT.Continue)
                    end
                })
                if not success then
                    callback(LOGIN_CHECK_STEP_RESULT.Continue)
                end
            else
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
            end
        end,
        interruptConfig = {
            [LoginCheckConflictConfigKey.BLACK_SCREEN] = true,
            [LoginCheckConflictConfigKey.NARRATIVE] = true,
            [LoginCheckConflictConfigKey.BLOCK_MSG] = true
        },
        waitConfig = {
            [LoginCheckConflictConfigKey.BLACK_SCREEN] = true,
            [LoginCheckConflictConfigKey.NARRATIVE] = true,
            [LoginCheckConflictConfigKey.BLOCK_MSG] = true
        }
    },
    { 
        key = LOGIN_CHECK_STEP_KEY.GUIDE,
        checkFunction = function(callback)
            local guideSystem = GameInstance.player.guide
            local findGuideGroup = guideSystem:TryCheckAndStartGuideGroup()
            if findGuideGroup then
                guideSystem:BindOnCompleteAction(function()
                    callback(LOGIN_CHECK_STEP_RESULT.Stop)
                    guideSystem:UnBindOnCompleteAction()
                end)
            else
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
            end
        end
    },
    { 
        key = LOGIN_CHECK_STEP_KEY.FORCE_SNS,
        checkFunction = function(callback)
            local sns = GameInstance.player.sns
            local findForceDialog = sns:TryCheckAndStartSNSForceDialog()
            if findForceDialog then
                sns:BindOnCompleteAction(function()
                    callback(LOGIN_CHECK_STEP_RESULT.Continue)
                    sns:UnBindCompleteAction()
                end)
            else
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
            end
        end
    },
}
