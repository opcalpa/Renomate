import { useState, useEffect } from "react";
import { FloorMapEditor } from "@/components/floormap/FloorMapEditor";
import { useTranslation } from "react-i18next";

interface SpacePlannerTabProps {
  projectId: string;
  projectName?: string;
  onBack?: () => void;
  isReadOnly?: boolean;
}

const SpacePlannerTab = ({ projectId, projectName, onBack, isReadOnly }: SpacePlannerTabProps) => {
  return <FloorMapEditor projectId={projectId} projectName={projectName} onBack={onBack} isReadOnly={isReadOnly} />;
};

export default SpacePlannerTab;
