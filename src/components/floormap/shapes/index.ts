/**
 * Shape Components Index
 *
 * Re-exports all shape components for the floor map canvas.
 */

// Types
export * from './types';

// Complex shapes with custom handles
export { WallShape } from './WallShape';
export { RoomShape } from './RoomShape';

// Basic shapes
export { RectangleShape, CircleShape, TextShape, FreehandShape } from './BasicShapes';

// Library shapes
export { LibrarySymbolShape, ObjectLibraryShape } from './LibraryShapes';
