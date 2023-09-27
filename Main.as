/*
c 2023-09-06
m 2023-09-06
*/

void Render() {
    auto App = cast<CTrackMania@>(GetApp());

    auto Playground = cast<CSmArenaClient@>(App.CurrentPlayground);
    if (Playground is null) return;



    auto Network = cast<CTrackManiaNetwork@>(App.Network);
    if (Network is null) return;

    auto ManiaApp = cast<CGameManiaAppPlayground@>(Network.ClientManiaAppPlayground);
    if (ManiaApp is null) return;

    auto Interface = cast<CGamePlaygroundInterface@>(Playground.Interface);
    if (Interface is null) return;

    auto Handler = cast<CGameScriptHandlerPlaygroundInterface@>(Interface.ManialinkScriptHandler);
    if (Handler is null) return;

    auto Api = cast<CGamePlaygroundClientScriptAPI@>(Handler.Playground);
    if (Api is null) return;

    UI::Begin("SpecCam", UI::WindowFlags::AlwaysAutoResize);
        UI::Text("spec: " + Api.IsSpectator);
        UI::Text("specClient: " + Api.IsSpectatorClient);
        UI::Text("ForceSpectator: " + ManiaApp.ClientUI.ForceSpectator);
        UI::Text("ForceCamType: " + ManiaApp.ClientUI.SpectatorForceCameraType);
        UI::Text("camType: " + tostring(Api.GetSpectatorCameraType()));
        UI::Text("targetType: " + tostring(Api.GetSpectatorTargetType()));
        if (UI::Button("toggle spec")) {
            Api.RequestSpectatorClient(!Api.IsSpectatorClient);
        }
        if (UI::Button("toggle force spec")) {
            ManiaApp.ClientUI.ForceSpectator = !ManiaApp.ClientUI.ForceSpectator;
        }
        if (UI::Button("set replay")) {
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Replay);
        }
        if (UI::Button("set follow")) {
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
        }
        // if (UI::Button("set follow all")) {
        //     Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
        // }
        if (UI::Button("set free")) {
            Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Free);
        }
        for (uint i = 0; i < Playground.Players.Length; i++) {
            auto Player = cast<CGamePlayer@>(Playground.Players[i]);
            if (UI::Selectable(Player.User.Name + " " + Player.User.Login, false)) {
                // ManiaApp.ClientUI.ForceSpectator = true;
                Api.SetSpectateTarget(Player.User.Login);
                Api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
            }
            // UI::Text(Player.User.Name + " " + Player.User.Login);
        }
    UI::End();
}