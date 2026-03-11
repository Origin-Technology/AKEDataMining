local LuaSystemBase = require_ex('LuaSystem/LuaSystemBase')














































LoginCheckSystem = HL.Class('LoginCheckSystem', LuaSystemBase.LuaSystemBase)


LoginCheckSystem.m_currentCheckStep = HL.Field(HL.Table)


LoginCheckSystem.m_waitingFirstStepRun = HL.Field(HL.Boolean) << true



LoginCheckSystem.m_isRunningStep = HL.Field(HL.Boolean) << false



LoginCheckSystem.m_isInterrupted = HL.Field(HL.Boolean) << false



LoginCheckSystem.m_checkingIndex = HL.Field(HL.Number) << -1



LoginCheckSystem.m_interruptHandlers = HL.Field(HL.Table)



LoginCheckSystem.m_loginChecked = HL.Field(HL.Boolean) << false



LoginCheckSystem.m_cachedCallback = HL.Field(HL.Function)



LoginCheckSystem.m_isResuming = HL.Field(HL.Boolean) << false



LoginCheckSystem.m_resumeFunc = HL.Field(HL.Function)


LoginCheckSystem.m_resumeCor = HL.Field(HL.Thread)


LoginCheckSystem.m_globalTagChangedCallback = HL.Field(HL.Userdata)



LoginCheckSystem.LoginCheckSystem = HL.Constructor() << function(self)
    self.m_currentCheckStep = nil
    self.m_interruptHandlers = {}
end



LoginCheckSystem.PerformLoginCheck = HL.Method() << function(self)
    if self.m_loginChecked then
        return
    end
    self.m_loginChecked = true

    self:InitializeCheck()

    if #LoginCheckConst.LOGIN_CHECK_STEP_CONFIG == 0 then
        self:_LoginCheckFinished()
        return
    end

    logger.important(CS.Beyond.EnableLogType.DevOnly, "[LoginCheck] 开始LoginCheck")
    self.m_checkingIndex = 1
    local firstStep = LoginCheckConst.LOGIN_CHECK_STEP_CONFIG[self.m_checkingIndex]
    self.m_waitingFirstStepRun = true
    self:_TryRunOrCacheCheckStep(firstStep)
end



LoginCheckSystem.InitializeCheck = HL.Method() << function(self)
    
    self:_AddInterruptSourceHandler(MessageConst.NOTIFY_MAIN_HUD_BLACK_SCREEN_BEGIN, MessageConst.NOTIFY_MAIN_HUD_BLACK_SCREEN_END)
    self:_AddInterruptSourceHandler(MessageConst.TOGGLE_LEVEL_CAMERA_MOVE, MessageConst.TOGGLE_LEVEL_CAMERA_MOVE)
    self:_RegisterOnGlobalTagChanged()

    
    self.m_cachedCallback = function(stepResult)
        self:_OnStepFinished(stepResult)
    end

    
    self:_RegisterTryGuarantee()
end



LoginCheckSystem._RegisterOnGlobalTagChanged = HL.Method() << function(self)
    if self.m_globalTagChangedCallback then
        
        return
    end
    local callback = function()
        if self.m_waitingFirstStepRun or self.m_isInterrupted then
            self:_TryResume()
        else
            self:_TryInterrupt()
        end
    end
    self.m_globalTagChangedCallback = CS.Beyond.Gameplay.GameplayUIUtils.RegisterOnGlobalTagChanged(callback)
end



LoginCheckSystem._UnRegisterOnGlobalTagChanged = HL.Method() << function(self)
    if self.m_globalTagChangedCallback then
        CS.Beyond.Gameplay.GameplayUIUtils.UnregisterOnGlobalTagChanged(self.m_globalTagChangedCallback)
        self.m_globalTagChangedCallback = nil
    end
end



LoginCheckSystem._TryInterrupt = HL.Method() << function(self)
    if not self.m_isRunningStep or self.m_isInterrupted then
        
        return
    end
    if not self:_CheckCanRunStep(true) then
        self.m_isInterrupted = true
        Notify(MessageConst.ON_LOGIN_CHECK_INTERRUPT, self.m_currentCheckStep.key)
    end
end



LoginCheckSystem._TryResume = HL.Method() << function(self)
    if not self.m_waitingFirstStepRun and (not self.m_isInterrupted or self.m_isResuming) then
        
        return
    end
    self.m_isResuming = true
    if self.m_resumeFunc == nil then
        self.m_resumeFunc = function()
            coroutine.step()
            self.m_isResuming = false
            if not self.m_isRunningStep then
                
                
                self:_TryRunCurrentCheckStep()
                return
            end
            if self:_CheckCanRunStep() then
                
                self.m_isInterrupted = false
                Notify(MessageConst.ON_LOGIN_RESUME, self.m_currentCheckStep.key)
            end
        end
    end
    self.m_resumeCor = self:_ClearCoroutine(self.m_resumeCor)
    self.m_resumeCor = self:_StartCoroutine(self.m_resumeFunc)
end





LoginCheckSystem._AddInterruptSourceHandler = HL.Method(HL.Number, HL.Number) << function(self, interruptMsg, resumeMsg)
    
    local handlerKey = MessageManager:Register(interruptMsg, function(args)
        self:_TryInterrupt()
    end)
    table.insert(self.m_interruptHandlers, handlerKey)

    
    handlerKey = MessageManager:Register(resumeMsg, function(args)
        self:_TryResume()
    end)
    table.insert(self.m_interruptHandlers, handlerKey)
end





LoginCheckSystem._TryRunOrCacheCheckStep = HL.Method(HL.Table) << function(self, stepConfig)
    self.m_currentCheckStep = stepConfig
    self.m_isRunningStep = false
    if stepConfig == nil or stepConfig.checkFunction == nil then
        self:_LoginCheckFinished()
        return
    end
    logger.important(CS.Beyond.EnableLogType.DevOnly, "[LoginCheck] 开始Check步骤", stepConfig.key)
    self:_TryRunCurrentCheckStep()
end




LoginCheckSystem._TryRunCurrentCheckStep = HL.Method() << function(self)
    self:_TryStartGuaranteeOnStepRun()
    if not self:_CheckCanRunStep() then
        return
    end
    self.m_isRunningStep = true
    self.m_waitingFirstStepRun = false
    self.m_currentCheckStep.checkFunction(self.m_cachedCallback)
end





LoginCheckSystem._CheckCanRunStep = HL.Method(HL.Opt(HL.Boolean)).Return(HL.Boolean) << function(self, checkInterrupt)
    if self.m_currentCheckStep == nil then
        return true
    end
    
    local checkConfig = checkInterrupt == true and self.m_currentCheckStep.interruptConfig or self.m_currentCheckStep.waitConfig
    if not checkConfig then
        return true
    end
    for key, checkEnabled in pairs(checkConfig) do
        local checkFunc = LoginCheckConst.LoginCheckConflictCheckFunc[key]
        if checkEnabled == true and checkFunc and checkFunc() then
            return false
        end
    end
    return true
end





LoginCheckSystem._OnStepFinished = HL.Method(HL.Number) << function(self, stepResult)
    if stepResult == LoginCheckConst.LOGIN_CHECK_STEP_RESULT.Continue then
        self.m_checkingIndex = self.m_checkingIndex + 1
    elseif stepResult == LoginCheckConst.LOGIN_CHECK_STEP_RESULT.BackToStart then
        self.m_checkingIndex = 1
    elseif stepResult == LoginCheckConst.LOGIN_CHECK_STEP_RESULT.BackToCurrent then
        
    elseif stepResult == LoginCheckConst.LOGIN_CHECK_STEP_RESULT.Stop then
        self:_LoginCheckFinished()
        return
    end

    local nextStep = LoginCheckConst.LOGIN_CHECK_STEP_CONFIG[self.m_checkingIndex]
    self:_TryRunOrCacheCheckStep(nextStep)
end




LoginCheckSystem._LoginCheckFinished = HL.Method() << function(self)
    self:_UnRegisterTryGuarantee()
    self:ReleaseCheck()
    logger.important(CS.Beyond.EnableLogType.DevOnly, "[LoginCheck] 已完成所有LoginCheck")
end




LoginCheckSystem.ReleaseCheck = HL.Method() << function(self)
    for index, handlerKey in pairs(self.m_interruptHandlers) do
        MessageManager:Unregister(handlerKey)
        self.m_interruptHandlers[index] = nil
    end
    self:_UnRegisterOnGlobalTagChanged()
    self.m_resumeCor = self:_ClearCoroutine(self.m_resumeCor)
    self.m_resumeFunc = nil
    self.m_cachedCallback = nil
end



LoginCheckSystem.OnRelease = HL.Override() << function(self)
    self:ReleaseCheck()
end


















local GUARANTEE_WAIT_COUNT = 90


LoginCheckSystem.m_tryGuaranteeMsgKey = HL.Field(HL.Number) << -1


LoginCheckSystem.m_guaranteeThread = HL.Field(HL.Thread)


LoginCheckSystem.m_currGuaranteeWaitCount = HL.Field(HL.Number) << 0



LoginCheckSystem._RegisterTryGuarantee = HL.Method() << function(self)
    self.m_tryGuaranteeMsgKey = MessageManager:Register(MessageConst.ON_IN_MAIN_HUD_CHANGED, function(msgArg)
        local inMainHud = unpack(msgArg)
        if inMainHud then
            self:_StartGuaranteeThread()
        else
            self:_ClearGuaranteeThread()
        end
    end, self)
    if GameWorld.worldInfo.inMainHud then
        self:_StartGuaranteeThread()
    end
end



LoginCheckSystem._UnRegisterTryGuarantee = HL.Method() << function(self)
    self:_ClearGuaranteeThread()
    MessageManager:Unregister(self.m_tryGuaranteeMsgKey)
end



LoginCheckSystem._StartGuaranteeThread = HL.Method() << function(self)
    self:_ClearGuaranteeThread()
    logger.important(CS.Beyond.EnableLogType.DevOnly, "[LoginCheck] 开始尝试触发保底")
    self.m_guaranteeThread = self:_StartCoroutine(function()
        while true do
            if GameInstance.player.guide.isInGuideIgnorePending then
                
                self:_ClearGuaranteeThread()
                break
            end

            self.m_currGuaranteeWaitCount = self.m_currGuaranteeWaitCount - 1
            if self.m_currGuaranteeWaitCount <= 0 then
                self:_GuaranteeToNextCheckStep()
                break
            end
            coroutine.step()
        end
    end)
end



LoginCheckSystem._ClearGuaranteeThread = HL.Method() << function(self)
    self.m_currGuaranteeWaitCount = GUARANTEE_WAIT_COUNT
    if self.m_guaranteeThread ~= nil then
        logger.important(CS.Beyond.EnableLogType.DevOnly, "[LoginCheck] 结束尝试触发保底")
        self.m_guaranteeThread = self:_ClearCoroutine(self.m_guaranteeThread)
    end
end



LoginCheckSystem._TryStartGuaranteeOnStepRun = HL.Method() << function(self)
    self:_ClearGuaranteeThread()
    if GameWorld.worldInfo.inMainHud then
        self:_StartGuaranteeThread()
    end
end



LoginCheckSystem._GuaranteeToNextCheckStep = HL.Method() << function(self)
    logger.critical("[LoginCheck] 步骤", self.m_checkingIndex, "非正常完成，触发保底措施")
    self:_ClearGuaranteeThread()
    self:_OnStepFinished(LoginCheckConst.LOGIN_CHECK_STEP_RESULT.Continue)
end




HL.Commit(LoginCheckSystem)
return LoginCheckSystem