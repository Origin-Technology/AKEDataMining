
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ActivityCharacterGuideWolfgd





ActivityCharacterGuideWolfgdCtrl = HL.Class('ActivityCharacterGuideWolfgdCtrl', uiCtrl.UICtrl)


ActivityCharacterGuideWolfgdCtrl.s_messages = HL.StaticField(HL.Table) << {
    
}


ActivityCharacterGuideWolfgdCtrl.m_activityId = HL.Field(HL.String) << ''




ActivityCharacterGuideWolfgdCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_activityId = args.activityId
    self.view.activityCommonInfo:InitActivityCommonInfo(args)
    self.view.btnDetailRedDot:InitRedDot("ActivityCharacterGuideLine", self.m_activityId)
end


HL.Commit(ActivityCharacterGuideWolfgdCtrl)
