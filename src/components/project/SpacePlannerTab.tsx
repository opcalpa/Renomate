import { useState, useEffect } from "react";
import { FloorMapEditor } from "@/components/floormap/FloorMapEditor";
import { useTranslation } from "react-i18next";

interface SpacePlannerTabProps {
  projectId: string;
  projectName?: string;
}

const SpacePlannerTab = ({ projectId, projectName }: SpacePlannerTabProps) => {
  return <FloorMapEditor projectId={projectId} projectName={projectName} />;
};

export default SpacePlannerTab;
