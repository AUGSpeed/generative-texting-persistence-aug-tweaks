// Initialize the texting system when the player spawns in
@wrapMethod(PlayerPuppet)
protected cb func OnMakePlayerVisibleAfterSpawn(evt: ref<EndGracePeriodAfterSpawn>) -> Bool { 
    wrappedMethod(evt);
    if !GameInstance.GetSystemRequestsHandler().IsPreGame() {
        if IsDefined(GetTextingSystem()) {
            GetTextingSystem().InitializeSystem();
        } else {
            ConsoleLog("Texting system not defined.");
        }
    }
}

@wrapMethod(PhoneDialerLogicController)
protected cb func OnAllElementsSpawned() -> Bool {
    wrappedMethod();

    if GetTextingSystem().GetUnread() {
        GetTextingSystem().HidePhoneUi();
    }
}

// Update the input hints based on the selected character
@wrapMethod(PhoneDialerLogicController)
private final func RefreshInputHints(contactData: wref<ContactData>) -> Void {
    wrappedMethod(contactData);

    if contactData != null {
        let contactName = contactData.contactId;
        ConsoleLog(s"Contact name: \(contactName)");
        // Check if the active character is selected

        if GetHttpRequestSystem().isGenerating || GetTextingSystem().sentModdedNotif {
            return;
        }

        if !isContactValidForAI(contactName) {
                if GetTextingSystem() != null {
                GetTextingSystem().ToggleNpcSelected(false);
            }
            return;
        } 

        if !Equals(contactName, GetCharacterContactName(GetTextingSystem().character)) {
            GetTextingSystem().character = GetCharacterSettingByContactName(contactName);
        }

        if Equals(contactName, GetCharacterContactName(GetTextingSystem().character)) {
            if GetTextingSystem() != null {
                GetTextingSystem().ToggleNpcSelected(true);
            }

            let contactListWidget = inkWidgetRef.Get(this.m_contactsList) as inkCompoundWidget;
            if IsDefined(contactListWidget) {

                let numChildren = contactListWidget.GetNumChildren();
                let i = 0;
                while i < numChildren {
                    let contactEntry = contactListWidget.GetWidgetByIndex(i) as inkCompoundWidget;
                    if IsDefined(contactEntry) {

                        // Check if this entry corresponds to npc's hints_holder
                        let contactLabel = FindWidgetWithName(contactEntry, n"contactLabel") as inkText;
                        if IsDefined(contactLabel) && Equals(contactLabel.GetText(), GetCharacterLocalizedName(GetTextingSystem().character)) {

                            // Locate the hints_holder within the npc's entry
                            let hintsHolderWidget = FindWidgetWithName(contactEntry, n"hints_holder") as inkHorizontalPanel;
                            if IsDefined(hintsHolderWidget) {

                                if NotEquals(s"\(hintsHolderWidget.parentWidget.GetName())", "horiz_holder") {
                                    return;
                                }

                                // Check if hint_mod already exists
                                let hintMod = FindWidgetWithName(hintsHolderWidget, n"hint_mod") as inkHorizontalPanel;
                                if IsDefined(hintMod) {

                                } else {
                                    // Create hint_mod since it doesn't exist
                                    hintMod = hintsHolderWidget.AddChild(n"inkHorizontalPanel") as inkHorizontalPanel;
                                    if IsDefined(hintMod) {
                                        hintMod.SetName(n"hint_mod");
                                        hintMod.SetVisible(true);
                                        hintMod.SetAnchor(inkEAnchor.TopRight);
                                        hintMod.SetVAlign(inkEVerticalAlign.Center);
                                        hintMod.SetHAlign(inkEHorizontalAlign.Right);

                                        // Add icon and text to hint_mod
                                        let keyWidget = hintMod.AddChild(n"inkImage") as inkImage;
                                        if IsDefined(keyWidget) {
                                            keyWidget.SetName(n"inputIcon");
                                            keyWidget.SetAtlasResource(r"base\\gameplay\\gui\\common\\input\\icons_keyboard.inkatlas");
                                            keyWidget.SetTexturePart(n"kb_t");
                                            keyWidget.SetSize(new Vector2(64.0, 64.0));
                                            keyWidget.SetScale(new Vector2(1, 1));
                                            keyWidget.SetAnchor(inkEAnchor.Centered);
                                            keyWidget.SetVisible(true);
                                            keyWidget.SetVAlign(inkEVerticalAlign.Center);
                                            keyWidget.SetHAlign(inkEHorizontalAlign.Center);
                                            keyWidget.BindProperty(n"tintColor", n"ContactListItem.fontColor");
                                            keyWidget.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
                                        }

                                        let iconWidget = hintMod.AddChild(n"inkImage") as inkImage;
                                        if IsDefined(iconWidget) {
                                            iconWidget.SetName(n"fluff");
                                            iconWidget.SetAtlasResource(r"base\\gameplay\\gui\\common\\icons\\atlas_common.inkatlas");
                                            iconWidget.SetTexturePart(n"ico_envelelope_reply1");
                                            iconWidget.SetSize(new Vector2(48.0, 48.0));    
                                            iconWidget.SetScale(new Vector2(1, 1));
                                            iconWidget.SetAnchor(inkEAnchor.TopLeft);
                                            iconWidget.SetVAlign(inkEVerticalAlign.Center);
                                            iconWidget.SetHAlign(inkEHorizontalAlign.Center);
                                            iconWidget.SetMargin(new inkMargin(7.0, 9.0, 8.0, 0.0));
                                            iconWidget.SetFitToContent(true);
                                            iconWidget.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
                                            iconWidget.BindProperty(n"tintColor", n"MainColors.Blue");
                                            iconWidget.BindProperty(n"opacity", n"MenuLabel.MainOpacity");
                                            iconWidget.SetVisible(true);
                                        }

                                        hintsHolderWidget.ReorderChild(hintMod, 0);
                                        
                                    } 
                                }
                            } 
                            break;
                        }
                    }
                    i += 1;
                }
            } else {
                ConsoleLog("contactListWidget not found.");
            }
        }
    }
}

// Toggle flags when the phone is put away
@wrapMethod(PhoneDialerLogicController)
public final func Hide() -> Void {
    wrappedMethod();

    if IsDefined(GetTextingSystem()) {
        GetTextingSystem().ToggleNpcSelected(false);
        GetTextingSystem().ToggleIsTyping(false);
    }
}

// Toggle flags when other menus are opened
@wrapMethod(MenuHubLogicController)
public final func SetActive(isActive: Bool) -> Void {
    wrappedMethod(isActive);

    if (IsDefined(GetTextingSystem()) && GetTextingSystem().GetChatOpen()) {
        GetTextingSystem().ToggleNpcSelected(false);
        GetTextingSystem().ToggleIsTyping(false);
        GetTextingSystem().HideModChat();
    }
}

// Toggle flags when the player enters combat
@wrapMethod(PlayerPuppet)
protected cb func OnCombatStateChanged(newState: Int32) -> Bool {  // newState uses the values specified in enum PlayerCombatState
    let r: Bool = wrappedMethod(newState);
    
    if Equals(newState, 1) {
        if (IsDefined(GetTextingSystem()) && GetTextingSystem().GetChatOpen()) {
            GetTextingSystem().ToggleNpcSelected(false);
            GetTextingSystem().ToggleIsTyping(false);
            GetTextingSystem().HideModChat();
        }
    }

    return r;
}

// Push a custom SMS notification based on the selected character and LLM response
@addMethod(NewHudPhoneGameController)
public final func PushCustomSMSNotification(text: String) -> Void {
    let notificationData: gameuiGenericNotificationData;
    let userData: ref<PhoneMessageNotificationViewData> = new PhoneMessageNotificationViewData();
    let action = new OpenGenerativePhoneMessageAction();
    action.m_phoneSystem = this.m_PhoneSystem;
    GetTextingSystem().sentModdedNotif = true;
    userData.title = GetCharacterLocalizedName(GetTextingSystem().character);
    userData.SMSText = text;
    userData.animation = n"notification_phone_MSG";
    userData.soundEvent = n"PhoneSmsPopup";
    userData.soundAction = n"OnOpen";
    userData.action = action;
    notificationData.time = 6.70;
    notificationData.widgetLibraryItemName = n"notification_message";
    notificationData.notificationData = userData;
    this.AddNewNotificationData(notificationData);
}

public class OpenGenerativePhoneMessageAction extends GenericNotificationBaseAction {

  public let m_phoneSystem: wref<PhoneSystem>;

  public let m_journalEntry: wref<JournalEntry>;

  public let m_characterName: String;

  public func Execute(data: ref<IScriptable>) -> Bool {
    GetTextingSystem().ToggleNpcSelected(true);
    let request: ref<UsePhoneRequest> = new UsePhoneRequest();
    request.MessageToOpen = this.m_journalEntry;
    ConsoleLog("Calling OpenGenerativePhoneMessageAction");
    this.m_phoneSystem.QueueRequest(request);
    return true;
  }

  public func GetLabel() -> String {
    return "[DB] Open Message";
  }
}

@wrapMethod(PhoneSystem)
private final func OnUsePhone(request: ref<UsePhoneRequest>) -> Void {
    ConsoleLog("CallingUsePhone");
    wrappedMethod(request);
    ConsoleLog("Finished Wrapped Method");
    if (GetTextingSystem().sentModdedNotif) {
        let delaySystem = GameInstance.GetDelaySystem(GetGameInstance());
        let inputInt: Int32 = 2;
        let delay: Float = 0.1;
        let isAffectedByTimeDilation: Bool = false;
        delaySystem.DelayCallback(CustomCallback.Create(inputInt), delay, isAffectedByTimeDilation);
    }
}

public class CustomCallback extends DelayCallback {
  // all the data that your Call function needs
  private let myInt: Int32;

  public func Call() {
    // custom function that i want to be called when the specified time has passed
    ConsoleLog("Modded Notif is True");
    GetTextingSystem().defaultPhoneController.DisableContactsInput();
    GetTextingSystem().ToggleContactList(false);
    GetTextingSystem().sentModdedNotif = false;
  }

  public static func Create(inputInt: Int32) -> ref<CustomCallback> {
    // use this way to create your Callback class in one line
    let self = new CustomCallback();

    self.myInt = inputInt;
    return self;
  }
}
