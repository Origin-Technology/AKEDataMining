local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ActivityHighDifficultyChallenge
local PHASE_ID = PhaseId.ActivityHighDifficultyChallenge















ActivityHighDifficultyChallengeCtrl = HL.Class('ActivityHighDifficultyChallengeCtrl', uiCtrl.UICtrl)







ActivityHighDifficultyChallengeCtrl.s_messages = HL.StaticField(HL.Table) << {
    
}


ActivityHighDifficultyChallengeCtrl.m_activityId = HL.Field(HL.String) << ''


ActivityHighDifficultyChallengeCtrl.m_activity = HL.Field(HL.Any)


ActivityHighDifficultyChallengeCtrl.m_listCells = HL.Field(HL.Any)


ActivityHighDifficultyChallengeCtrl.m_seriesCount = HL.Field(HL.Number) << 0


ActivityHighDifficultyChallengeCtrl.m_allSeries = HL.Field(HL.Table)


ActivityHighDifficultyChallengeCtrl.m_firstCell = HL.Field(HL.Any)


ActivityHighDifficultyChallengeCtrl.m_focusCell = HL.Field(HL.Any)


ActivityHighDifficultyChallengeCtrl.m_initSeriesId = HL.Field(HL.String) << ""





ActivityHighDifficultyChallengeCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    
    self.view.btnClose.onClick:AddListener(function()
        self:_Close(args)
    end)

    
    self.m_activityId = args.activityId
    self.m_initSeriesId = args.seriesId or ""
    self.m_activity = GameInstance.player.activitySystem:GetActivity(self.m_activityId)
    self.m_seriesCount = 0
    self.m_allSeries = {}
    local _, seriesCfg = Tables.activityGameEntranceSeriesTable:TryGetValue(self.m_activityId)
    for id, seriesInfo in pairs(self.m_activity.seriesDataMap) do
        self.m_seriesCount = self.m_seriesCount + 1;
        local sortId = seriesCfg.seriesMap[seriesInfo.SeriesId].sortId
        table.insert(self.m_allSeries,{
            seriesId = seriesInfo.SeriesId,
            openTime = seriesInfo.OpenTime,
            sortId = sortId,
        })
    end
    table.sort(self.m_allSeries, Utils.genSortFunction({"sortId"}, true))

    
    if #self.m_allSeries == 0 then
        self:_Close(args)
    end

    
    if self.m_seriesCount >= ActivityConst.ACTIVITY_HIGH_DIFFICULTY_MULTIPLE_NUMBER then
        self.view.main:SetState("Multiple")
    else
        self.view.main:SetState("Single")
    end

    
    self.m_listCells = UIUtils.genCellCache(self.view.itemChallengeCell)
    self.m_listCells:Refresh(math.max(ActivityConst.ACTIVITY_HIGH_DIFFICULTY_MULTIPLE_NUMBER - 1, self.m_seriesCount), function(cell, index)
        self:_UpdateCell(cell, index)
    end)
    self.view.levelsScrollList.horizontalNormalizedPosition = 1

    
    if DeviceInfo.usingController then
        UIUtils.setAsNaviTarget(self.m_focusCell and self.m_focusCell.cellNaviDeco or self.m_firstCell.cellNaviDeco)
        self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
    end
end






ActivityHighDifficultyChallengeCtrl._UpdateCell = HL.Method(HL.Any,HL.Number) << function(self,cell,index)
    
    if index == 1 and not self.m_firstCell then
        self.m_firstCell = cell
    end
    cell.cellNaviDeco.onIsNaviTargetChanged = function(isTarget)
        if isTarget then
            self.m_focusCell = cell
        end
    end

    
    if index > self.m_seriesCount then
        cell.nodeState:SetState("EmptyNode")
        return
    end

     
    local seriesId = self.m_allSeries[index].seriesId
    if seriesId == self.m_initSeriesId then
        self.m_firstCell = cell
    end
    local unlocked = GameInstance.player.activitySystem:IsGameEntranceSeriesUnlock(seriesId)
    if unlocked and index <= self.m_seriesCount then
        cell.nodeState:SetState("NormalNode")
    else
        cell.nodeState:SetState("EmptyNode")
        return
    end

    
    local _, seriesCfg = Tables.activityGameEntranceSeriesTable:TryGetValue(self.m_activityId)
    cell.nameTxt.text = seriesCfg.seriesMap[seriesId].name
    local path = UIConst.UI_SPRITE_ACTIVITY
    local name = seriesCfg.seriesMap[seriesId].bgImg
    cell.bgImg:LoadSprite(path,name)
    cell.redDot:InitRedDot("ActivityHighDifficultyChallengeCell", {self.m_activityId, seriesId})

    
    local achievementId = seriesCfg.seriesMap[seriesId].achieveId
    cell.dungeonMedalCell:InitCommonMedalNode(achievementId)

    
    if DeviceInfo.usingTouch then
        cell.normalNode:SetState("Mobile")
    else
        cell.normalNode:SetState("Standatone")
    end
    local gameList = Tables.ActivityGameEntranceGameTable[seriesId].gameList

    
    local allPassed = true
    for i = 0,#gameList/2 -1 do
        local normalPassed = GameInstance.dungeonManager:IsDungeonPassed(gameList[2*i].gameId)
        local raidPassed = GameInstance.dungeonManager:IsDungeonPassed(gameList[2*i+1].gameId)
        if not normalPassed or not raidPassed then
            allPassed = false
        end
        local stateController = "levelsState"..tostring(LuaIndex(i))
        cell[stateController]:SetState(not normalPassed and "Normal" or raidPassed and "Raid" or "Ordinary" )
    end
    if allPassed then
        cell.sliderState:SetState("FinishNode")
    else
        cell.sliderState:SetState("ConductNode")
    end

    
    cell.clickBtn.onClick:RemoveAllListeners()
    cell.clickBtn.onClick:AddListener(function()
        local dungeonId = gameList[0].gameId
        local dungeonSeriesId = Tables.dungeonTable[dungeonId].dungeonSeriesId
        local activityId = self.m_activityId
        local enterDungeonCallback
        enterDungeonCallback = function(enterDungeonId)
            LuaSystemManager.uiRestoreSystem:AddRequest(enterDungeonId, function()
                PhaseManager:OpenPhaseFast(PhaseId.ActivityCenter, { gotoCenter = true, activityId = activityId })
                PhaseManager:OpenPhaseFast(PhaseId.ActivityHighDifficultyChallenge, { activityId = activityId, seriesId = seriesId })
                PhaseManager:OpenPhaseFast(PhaseId.DungeonEntry, {
                    dungeonId = enterDungeonId,
                    enterDungeonCallback = enterDungeonCallback
                })
            end)
        end
        Notify(MessageConst.ON_OPEN_DUNGEON_ENTRY_PANEL, {
            dungeonSeriesId,
            enterDungeonCallback,
        })
        ActivityUtils.setFalseNewActivityHighDifficultySeries(self.m_activityId, seriesId)
    end)
end




ActivityHighDifficultyChallengeCtrl._Close = HL.Method(HL.Table) << function(self, args)
    if args and args.fromDialog then
        Notify(MessageConst.DIALOG_CLOSE_UI, { PANEL_ID, PHASE_ID, 0 })
    else
        PhaseManager:PopPhase(PHASE_ID)
    end
end




ActivityHighDifficultyChallengeCtrl._OnPanelInputBlocked = HL.Override(HL.Boolean) << function(self, active)
    if active and DeviceInfo.usingController then
        UIUtils.setAsNaviTarget(self.m_focusCell and self.m_focusCell.cellNaviDeco or self.m_firstCell.cellNaviDeco)
    end
end

HL.Commit(ActivityHighDifficultyChallengeCtrl)