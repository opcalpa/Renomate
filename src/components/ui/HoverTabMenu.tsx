import React, { useState, useRef } from 'react';
import { cn } from '@/lib/utils';

interface MenuItem {
  label: string;
  value: string;
  description?: string;
}

interface HoverTabMenuProps {
  trigger: React.ReactNode;
  items: MenuItem[];
  onSelect: (value: string) => void;
  onMainClick?: () => void;
  activeValue?: string;
  className?: string;
}

export const HoverTabMenu: React.FC<HoverTabMenuProps> = ({
  trigger,
  items,
  onSelect,
  onMainClick,
  activeValue,
  className
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const timeoutRef = useRef<NodeJS.Timeout>();
  const menuRef = useRef<HTMLDivElement>(null);

  const handleMouseEnter = () => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    setIsOpen(true);
  };

  const handleMouseLeave = () => {
    timeoutRef.current = setTimeout(() => {
      setIsOpen(false);
    }, 150); // Small delay to prevent flickering
  };

  const handleItemClick = (value: string) => {
    setIsOpen(false);
    onSelect(value);
  };

  return (
    <div
      className={cn("relative", className)}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      ref={menuRef}
    >
      {/* Trigger/Button */}
      <div
        className={cn(
          "cursor-pointer transition-colors duration-200",
          activeValue && "font-semibold"
        )}
        onClick={onMainClick}
      >
        {trigger}
      </div>

      {/* Dropdown Menu */}
      {isOpen && (
        <div
          className="absolute top-full left-0 mt-1 bg-white border border-gray-200 rounded-md shadow-lg z-50 min-w-[200px] py-1"
          onMouseEnter={() => {
            if (timeoutRef.current) {
              clearTimeout(timeoutRef.current);
            }
          }}
          onMouseLeave={handleMouseLeave}
        >
          {items.map((item) => (
            <button
              key={item.value}
              onClick={() => handleItemClick(item.value)}
              className={cn(
                "w-full text-left px-4 py-2 hover:bg-gray-50 transition-colors duration-150",
                activeValue === item.value && "bg-blue-50 text-blue-700 font-medium"
              )}
            >
              <div className="font-medium">{item.label}</div>
              {item.description && (
                <div className="text-sm text-gray-500 mt-0.5">{item.description}</div>
              )}
            </button>
          ))}
        </div>
      )}
    </div>
  );
};