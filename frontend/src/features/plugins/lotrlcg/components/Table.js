import React, { useEffect } from "react";
import { TableLayout } from "../../../engine/TableLayout";
import { GiantCard } from "../../../engine/GiantCard";
import { TopBar } from "./TopBar";
import { SpawnCardModal } from "../../../engine/SpawnCardModal";
import { SpawnCustomModal } from "./SpawnCustomModal";
import { SpawnQuestModal } from "./SpawnQuestModal";
import { SpawnCampaignModal } from "./SpawnCampaignModal";
import { SideBar } from "../../../engine/SideBar";
import { Hotkeys } from "./Hotkeys";
import { PlayersInRoom } from "../../../engine/PlayersInRoom";
import { DropdownMenu } from "../../../engine/DropdownMenu";
import { TouchBarBottom } from "./TouchBarBottom";

import "../../../../css/custom-dropdown.css";
import { TooltipModal } from "../../../engine/TooltipModal";
import { setActiveCardObj, setDropdownMenuObj, setMousePosition, setTouchAction } from "../../../store/playerUiSlice";
import { useDispatch, useSelector } from "react-redux";
import useProfile from "../../../../hooks/useProfile";
import { onLoad } from "../functions/helpers";

export const Table = React.memo(({
  gameBroadcast,
  chatBroadcast,
  registerDivToArrowsContext
}) => {
  console.log('Rendering Table');
  const dispatch = useDispatch();
  const tooltipIds = useSelector(state => state?.playerUi?.tooltipIds);
  const touchMode = useSelector(state => state?.playerUi?.touchMode);
  const showModal = useSelector(state => state?.playerUi?.showModal);
  const options = useSelector(state => state?.gameUi?.game?.options); 
  const loaded = useSelector(state => state?.playerUi?.loaded);
  const myUserId = useProfile()?.id;
  const createdBy = useSelector(state => state.gameUi?.created_by);
  const isHost = myUserId === createdBy;

  const handleTableClick = (event) => {
    dispatch(setActiveCardObj(null));
    dispatch(setDropdownMenuObj(null));
    dispatch(setTouchAction(null));
  }

  // useEffect(() => {
  //   if (!loaded && isHost && gameBroadcast) useOnLoad(options, gameBroadcast, chatBroadcast, dispatch);
  // },[loaded, gameBroadcast])
  if (!loaded && isHost) onLoad(options, gameBroadcast, chatBroadcast, dispatch);

  useEffect(() => {
    const handleMouseDown = (event) => {
      dispatch(setMousePosition({
        x: event.clientX,
        y: event.clientY,
      }))
    }
    document.addEventListener('mousedown', handleMouseDown);
    return () => {
      document.removeEventListener('mousedown', handleMouseDown);
    }
  })

  return (
    <div className="h-full flex" style={{fontSize: "1.7vh"}}
      //onTouchStart={(event) => handleTableClick(event)} onMouseUp={(event) => handleTableClick(event)}
      onClick={(event) => handleTableClick(event)}>
      <DropdownMenu
        gameBroadcast={gameBroadcast}
        chatBroadcast={chatBroadcast}
      />
      <Hotkeys/>
      <PlayersInRoom/>
      {/* Side panel */}
      <SideBar
        gameBroadcast={gameBroadcast}
        chatBroadcast={chatBroadcast}
      />
      {/* Main panel */}
      <div className="w-full">
        <div className="w-full h-full">
          {/* Game menu bar */}
          <div className="bg-gray-600 text-white w-full" style={{height: "6%"}}>
            <TopBar
              gameBroadcast={gameBroadcast}
              chatBroadcast={chatBroadcast}
            />
          </div>
          {/* Table */}
          <div className="relative w-full" style={{height: touchMode ? "82%" : "94%"}}>
            <TableLayout
              gameBroadcast={gameBroadcast} 
              chatBroadcast={chatBroadcast}
              registerDivToArrowsContext={registerDivToArrowsContext}
            />
          </div>
          {/* Touch Bar */}
          {touchMode && <div className="relative bg-gray-700 w-full" style={{height: "12%"}}>
              <TouchBarBottom/>
          </div>}
        </div>
      </div>
      {/* Card hover view */}
      <GiantCard/>
      {showModal === "card" ? <SpawnCardModal gameBroadcast={gameBroadcast} chatBroadcast={chatBroadcast}/> : null}
      {showModal === "quest" ? <SpawnQuestModal gameBroadcast={gameBroadcast} chatBroadcast={chatBroadcast}/> : null}
      {showModal === "custom" ? <SpawnCustomModal gameBroadcast={gameBroadcast} chatBroadcast={chatBroadcast}/> : null}
      {showModal === "campaign" ? <SpawnCampaignModal gameBroadcast={gameBroadcast} chatBroadcast={chatBroadcast}/> : null}
      {tooltipIds.map((tooltipId, index) => {
        return(
        <TooltipModal
          tooltipId={tooltipId}
        />)
      })}
    </div>
  );
})






