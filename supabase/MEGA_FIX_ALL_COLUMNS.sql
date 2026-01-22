-- ============================================
-- MEGA FIX - ALL POSSIBLE MISSING COLUMNS
-- Run this ONCE to add ALL columns that might be missing
-- ============================================

-- ============================================
-- PROJECTS TABLE
-- ============================================
ALTER TABLE public.projects
ADD COLUMN IF NOT EXISTS budget DECIMAL(12, 2),
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE,
ADD COLUMN IF NOT EXISTS start_goal_date DATE,
ADD COLUMN IF NOT EXISTS finish_goal_date DATE,
ADD COLUMN IF NOT EXISTS actual_start_date DATE,
ADD COLUMN IF NOT EXISTS actual_end_date DATE,
ADD COLUMN IF NOT EXISTS actual_finish_date DATE,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS postal_code TEXT,
ADD COLUMN IF NOT EXISTS country TEXT DEFAULT 'Sweden',
ADD COLUMN IF NOT EXISTS progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- ============================================
-- ROOMS TABLE
-- ============================================
ALTER TABLE public.rooms
ADD COLUMN IF NOT EXISTS budget DECIMAL(12, 2),
ADD COLUMN IF NOT EXISTS estimated_cost DECIMAL(12, 2),
ADD COLUMN IF NOT EXISTS actual_cost DECIMAL(12, 2),
ADD COLUMN IF NOT EXISTS area DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS floor_level INTEGER,
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'planning',
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS color TEXT,
ADD COLUMN IF NOT EXISTS progress INTEGER DEFAULT 0;

-- ============================================
-- TASKS TABLE
-- ============================================
ALTER TABLE public.tasks
ADD COLUMN IF NOT EXISTS budget DECIMAL(12, 2),
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE,
ADD COLUMN IF NOT EXISTS finish_date DATE,
ADD COLUMN IF NOT EXISTS goal_date DATE,
ADD COLUMN IF NOT EXISTS actual_start_date DATE,
ADD COLUMN IF NOT EXISTS actual_finish_date DATE,
ADD COLUMN IF NOT EXISTS estimated_cost DECIMAL(12, 2),
ADD COLUMN IF NOT EXISTS actual_cost DECIMAL(12, 2),
ADD COLUMN IF NOT EXISTS paid_amount DECIMAL(12, 2),
ADD COLUMN IF NOT EXISTS payment_status TEXT,
ADD COLUMN IF NOT EXISTS estimated_hours DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS actual_hours DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS attachments JSONB,
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS blocked_reason TEXT;

-- ============================================
-- MATERIALS TABLE
-- ============================================
ALTER TABLE public.materials
ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS room_id UUID REFERENCES public.rooms(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS purchase_date DATE,
ADD COLUMN IF NOT EXISTS delivery_date DATE,
ADD COLUMN IF NOT EXISTS ordered_date DATE,
ADD COLUMN IF NOT EXISTS installed_date DATE,
ADD COLUMN IF NOT EXISTS supplier TEXT,
ADD COLUMN IF NOT EXISTS supplier_contact TEXT,
ADD COLUMN IF NOT EXISTS warranty_info TEXT,
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- ============================================
-- CONTRACTORS TABLE
-- ============================================
ALTER TABLE public.contractors
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS postal_code TEXT,
ADD COLUMN IF NOT EXISTS country TEXT,
ADD COLUMN IF NOT EXISTS website TEXT,
ADD COLUMN IF NOT EXISTS rating DECIMAL(3, 2),
ADD COLUMN IF NOT EXISTS specialties TEXT[],
ADD COLUMN IF NOT EXISTS insurance_info TEXT,
ADD COLUMN IF NOT EXISTS license_number TEXT,
ADD COLUMN IF NOT EXISTS tax_id TEXT;

-- ============================================
-- PURCHASE_REQUESTS TABLE
-- ============================================
ALTER TABLE public.purchase_requests
ADD COLUMN IF NOT EXISTS approved_by_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- ============================================
-- PROJECT_INVITATIONS TABLE
-- ============================================
ALTER TABLE public.project_invitations
ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMPTZ;

-- ============================================
-- UPDATE EXISTING DATA
-- ============================================

-- Update materials with project_id from tasks
UPDATE public.materials m
SET project_id = t.project_id
FROM public.tasks t
WHERE m.task_id = t.id AND m.project_id IS NULL;

-- Update materials with room_id from tasks
UPDATE public.materials m
SET room_id = t.room_id
FROM public.tasks t
WHERE m.task_id = t.id AND m.room_id IS NULL;

-- ============================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================

-- Projects indexes
CREATE INDEX IF NOT EXISTS idx_projects_budget ON public.projects(budget);
CREATE INDEX IF NOT EXISTS idx_projects_start_date ON public.projects(start_date);
CREATE INDEX IF NOT EXISTS idx_projects_finish_goal_date ON public.projects(finish_goal_date);
CREATE INDEX IF NOT EXISTS idx_projects_progress ON public.projects(progress);
CREATE INDEX IF NOT EXISTS idx_projects_status ON public.projects(status);

-- Rooms indexes
CREATE INDEX IF NOT EXISTS idx_rooms_budget ON public.rooms(budget);
CREATE INDEX IF NOT EXISTS idx_rooms_status ON public.rooms(status);
CREATE INDEX IF NOT EXISTS idx_rooms_progress ON public.rooms(progress);

-- Tasks indexes
CREATE INDEX IF NOT EXISTS idx_tasks_budget ON public.tasks(budget);
CREATE INDEX IF NOT EXISTS idx_tasks_start_date ON public.tasks(start_date);
CREATE INDEX IF NOT EXISTS idx_tasks_finish_date ON public.tasks(finish_date);
CREATE INDEX IF NOT EXISTS idx_tasks_goal_date ON public.tasks(goal_date);
CREATE INDEX IF NOT EXISTS idx_tasks_progress ON public.tasks(progress);
CREATE INDEX IF NOT EXISTS idx_tasks_payment_status ON public.tasks(payment_status);
CREATE INDEX IF NOT EXISTS idx_tasks_completed_at ON public.tasks(completed_at);

-- Materials indexes
CREATE INDEX IF NOT EXISTS idx_materials_project_id ON public.materials(project_id);
CREATE INDEX IF NOT EXISTS idx_materials_room_id ON public.materials(room_id);
CREATE INDEX IF NOT EXISTS idx_materials_status ON public.materials(status);
CREATE INDEX IF NOT EXISTS idx_materials_purchase_date ON public.materials(purchase_date);

-- Purchase requests indexes
CREATE INDEX IF NOT EXISTS idx_purchase_requests_status ON public.purchase_requests(status);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_approved_by ON public.purchase_requests(approved_by_user_id);

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
-- All columns added successfully!
-- Your database is now complete and ready to use.
