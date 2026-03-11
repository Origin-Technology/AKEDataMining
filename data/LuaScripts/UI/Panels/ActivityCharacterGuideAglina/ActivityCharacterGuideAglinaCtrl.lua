
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ActivityCharacterGuideAglina

ActivityCharacterGuideAglinaCtrl = HL.Class('ActivityCharacterGuideAglinaCtrl', uiCtrl.UICtrl)

ActivityCharacterGuideAglinaCtrl.s_messages = HL.StaticField(HL.Table) << {
    
}


ActivityCharacterGuideAglinaCtrl.m_activityId = HL.Field(HL.String) << ''

ActivityCharacterGuideAglinaCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_activityId = args.activityId
    self.view.activityCommonInfo:InitActivityCommonInfo(args)
    self.view.btnDetailRedDot:InitRedDot("ActivityCharacterGuideLine", self.m_activityId)
end


HL.Commit(ActivityCharacterGuideAglinaCtrl)
