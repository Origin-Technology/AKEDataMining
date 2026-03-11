
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ActivityCharacterGuideYvonne





ActivityCharacterGuideYvonneCtrl = HL.Class('ActivityCharacterGuideYvonneCtrl', uiCtrl.UICtrl)







ActivityCharacterGuideYvonneCtrl.s_messages = HL.StaticField(HL.Table) << {
    
}


ActivityCharacterGuideYvonneCtrl.m_activityId = HL.Field(HL.String) << ''





ActivityCharacterGuideYvonneCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_activityId = args.activityId
    self.view.activityCommonInfo:InitActivityCommonInfo(args)
    self.view.btnDetailRedDot:InitRedDot("ActivityCharacterGuideLine", self.m_activityId)
end

HL.Commit(ActivityCharacterGuideYvonneCtrl)
