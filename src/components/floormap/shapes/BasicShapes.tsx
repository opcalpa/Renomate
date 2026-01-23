/**
 * Basic Shape Components
 *
 * Simple shape renderers for Rectangle, Circle, Text, and Freehand.
 */

import React, { useRef, useEffect } from 'react';
import { Rect, Circle, Line, Text as KonvaText } from 'react-konva';
import Konva from 'konva';
import { useFloorMapStore } from '../store';
import { ShapeComponentProps } from './types';

/**
 * RectangleShape - Renders rectangle, door, and opening shapes
 * PERFORMANCE: Memoized to prevent unnecessary re-renders
 */
export const RectangleShape = React.memo<ShapeComponentProps>(({ shape, isSelected, onSelect, onTransform, shapeRefsMap }) => {
  const shapeRef = useRef<Konva.Rect>(null);

  // Store ref in shapeRefsMap for unified multi-select drag
  useEffect(() => {
    if (shapeRef.current && shapeRefsMap) {
      shapeRefsMap.set(shape.id, shapeRef.current);
      return () => {
        shapeRefsMap.delete(shape.id);
      };
    }
  }, [shape.id, shapeRefsMap]);

  if (shape.type !== 'rectangle' && shape.type !== 'door' && shape.type !== 'opening') return null;

  const coords = shape.coordinates as { left: number; top: number; width: number; height: number };

  const isDraggable = true; // Always draggable

  return (
    <Rect
      id={`shape-${shape.id}`}
      ref={shapeRef}
      name={shape.id}
      shapeId={shape.id}
      x={coords.left}
      y={coords.top}
      width={coords.width}
      height={coords.height}
      fill={shape.color || 'transparent'}
      stroke={isSelected ? '#3b82f6' : shape.strokeColor || '#000000'}
      strokeWidth={2}
      cornerRadius={2}
      draggable={isDraggable}
      onClick={(e) => {
        e.cancelBubble = true;
        onSelect(e);
      }}
      onTap={(e) => {
        e.cancelBubble = true;
        onSelect(e);
      }}
      onDragStart={(e) => {
        e.cancelBubble = true;
      }}
      onDragEnd={(e) => {
        e.cancelBubble = true;
        const node = e.target;

        onTransform({
          coordinates: {
            left: node.x(),
            top: node.y(),
            width: coords.width,
            height: coords.height,
          }
        });

        node.position({ x: 0, y: 0 });
      }}
      onTransformEnd={(e) => {
        const node = shapeRef.current;
        if (!node) return;

        const scaleX = node.scaleX();
        const scaleY = node.scaleY();

        node.scaleX(1);
        node.scaleY(1);

        onTransform({
          coordinates: {
            left: node.x(),
            top: node.y(),
            width: Math.max(5, node.width() * scaleX),
            height: Math.max(5, node.height() * scaleY),
          }
        });
      }}
    />
  );
}, (prevProps, nextProps) => {
  const coordsEqual = JSON.stringify(prevProps.shape.coordinates) === JSON.stringify(nextProps.shape.coordinates);

  return (
    prevProps.shape.id === nextProps.shape.id &&
    prevProps.isSelected === nextProps.isSelected &&
    coordsEqual &&
    prevProps.shape.color === nextProps.shape.color &&
    prevProps.shape.strokeColor === nextProps.shape.strokeColor
  );
});

/**
 * CircleShape - Renders circle shapes
 * PERFORMANCE: Memoized to prevent unnecessary re-renders
 */
export const CircleShape = React.memo<ShapeComponentProps>(({ shape, isSelected, onSelect, onTransform, shapeRefsMap }) => {
  const shapeRef = useRef<Konva.Circle>(null);

  // Store ref in shapeRefsMap for unified multi-select drag
  useEffect(() => {
    if (shapeRef.current && shapeRefsMap) {
      shapeRefsMap.set(shape.id, shapeRef.current);
      return () => {
        shapeRefsMap.delete(shape.id);
      };
    }
  }, [shape.id, shapeRefsMap]);

  if (shape.type !== 'circle') return null;

  const coords = shape.coordinates as { cx: number; cy: number; radius: number };

  const isDraggable = true; // Always draggable

  return (
    <Circle
      id={`shape-${shape.id}`}
      ref={shapeRef}
      name={shape.id}
      shapeId={shape.id}
      x={coords.cx}
      y={coords.cy}
      radius={coords.radius}
      fill={shape.color || 'transparent'}
      stroke={isSelected ? '#3b82f6' : shape.strokeColor || '#000000'}
      strokeWidth={2}
      draggable={isDraggable}
      onClick={(e) => {
        e.cancelBubble = true;
        onSelect(e);
      }}
      onTap={(e) => {
        e.cancelBubble = true;
        onSelect(e);
      }}
      onDragStart={(e) => {
        e.cancelBubble = true;
      }}
      onDragEnd={(e) => {
        e.cancelBubble = true;
        const node = e.target;

        onTransform({
          coordinates: {
            cx: node.x(),
            cy: node.y(),
            radius: coords.radius,
          }
        });

        node.position({ x: 0, y: 0 });
      }}
    />
  );
}, (prevProps, nextProps) => {
  const coordsEqual = JSON.stringify(prevProps.shape.coordinates) === JSON.stringify(nextProps.shape.coordinates);

  return (
    prevProps.shape.id === nextProps.shape.id &&
    prevProps.isSelected === nextProps.isSelected &&
    coordsEqual &&
    prevProps.shape.color === nextProps.shape.color &&
    prevProps.shape.strokeColor === nextProps.shape.strokeColor
  );
});

/**
 * TextShape - Renders text shapes
 * PERFORMANCE: Memoized to prevent unnecessary re-renders
 */
export const TextShape = React.memo<ShapeComponentProps>(({ shape, isSelected, onSelect, onTransform, shapeRefsMap }) => {
  const textRef = useRef<Konva.Text>(null);

  // Store ref in shapeRefsMap for unified multi-select drag
  useEffect(() => {
    if (textRef.current && shapeRefsMap) {
      shapeRefsMap.set(shape.id, textRef.current);
      return () => {
        shapeRefsMap.delete(shape.id);
      };
    }
  }, [shape.id, shapeRefsMap]);

  if (shape.type !== 'text') return null;

  const coords = shape.coordinates as { x: number; y: number };

  const isDraggable = true; // Always draggable

  return (
    <KonvaText
      id={`shape-${shape.id}`}
      ref={textRef}
      name={shape.id}
      shapeId={shape.id}
      x={coords.x}
      y={coords.y}
      text={shape.text || 'Text'}
      fontSize={shape.metadata?.lengthMM || 16}
      fill={shape.color || '#000000'}
      draggable={isDraggable}
      onClick={(e) => {
        e.cancelBubble = true;
        onSelect(e);
      }}
      onTap={(e) => {
        e.cancelBubble = true;
        onSelect(e);
      }}
      rotation={shape.rotation || 0}
      onDragStart={(e) => {
        e.cancelBubble = true;
      }}
      onDragEnd={(e) => {
        e.cancelBubble = true;
        const node = e.target;

        onTransform({
          coordinates: {
            x: node.x(),
            y: node.y(),
          }
        });

        node.position({ x: 0, y: 0 });
      }}
    />
  );
}, (prevProps, nextProps) => {
  const coordsEqual = JSON.stringify(prevProps.shape.coordinates) === JSON.stringify(nextProps.shape.coordinates);

  return (
    prevProps.shape.id === nextProps.shape.id &&
    prevProps.isSelected === nextProps.isSelected &&
    coordsEqual &&
    prevProps.shape.text === nextProps.shape.text &&
    prevProps.shape.color === nextProps.shape.color &&
    prevProps.shape.rotation === nextProps.shape.rotation &&
    prevProps.shape.metadata?.lengthMM === nextProps.shape.metadata?.lengthMM
  );
});

/**
 * FreehandShape - Renders freehand/polygon shapes
 * PERFORMANCE: Memoized to prevent unnecessary re-renders
 */
export const FreehandShape = React.memo<ShapeComponentProps>(({ shape, isSelected, onSelect, onTransform, shapeRefsMap }) => {
  const shapeRef = useRef<Konva.Line>(null);

  // Store ref in shapeRefsMap for unified multi-select drag
  useEffect(() => {
    if (shapeRef.current && shapeRefsMap) {
      shapeRefsMap.set(shape.id, shapeRef.current);
      return () => {
        shapeRefsMap.delete(shape.id);
      };
    }
  }, [shape.id, shapeRefsMap]);

  if (shape.type !== 'freehand' && shape.type !== 'polygon') return null;

  const coords = shape.coordinates as { points: { x: number; y: number }[] };
  const points = coords.points || [];
  const flatPoints = points.flatMap((p: { x: number; y: number }) => [p.x, p.y]);

  const isDraggable = true; // Always draggable

  return (
    <Line
      ref={shapeRef}
      id={`shape-${shape.id}`}
      name={shape.id}
      shapeId={shape.id}
      points={flatPoints}
      stroke={isSelected ? '#3b82f6' : shape.strokeColor || '#000000'}
      strokeWidth={shape.strokeWidth || 2}
      tension={0.5}
      lineCap="round"
      lineJoin="round"
      draggable={isDraggable}
      // PERFORMANCE: Disable perfect draw for faster rendering
      perfectDrawEnabled={false}
      hitStrokeWidth={10}
      onClick={(e) => {
        e.cancelBubble = true;
        onSelect(e);
      }}
      onTap={(e) => {
        e.cancelBubble = true;
        onSelect(e);
      }}
      onDragStart={(e) => {
        e.cancelBubble = true;
      }}
      onDragEnd={(e) => {
        e.cancelBubble = true;
        const node = e.target;
        const deltaX = node.x();
        const deltaY = node.y();

        const newPoints = points.map((p: { x: number; y: number }) => ({
          x: p.x + deltaX,
          y: p.y + deltaY
        }));

        onTransform({
          coordinates: { points: newPoints }
        });

        node.position({ x: 0, y: 0 });
      }}
    />
  );
}, (prevProps, nextProps) => {
  const coordsEqual = JSON.stringify(prevProps.shape.coordinates) === JSON.stringify(nextProps.shape.coordinates);

  return (
    prevProps.shape.id === nextProps.shape.id &&
    prevProps.isSelected === nextProps.isSelected &&
    coordsEqual &&
    prevProps.shape.color === nextProps.shape.color &&
    prevProps.shape.strokeColor === nextProps.shape.strokeColor
  );
});
