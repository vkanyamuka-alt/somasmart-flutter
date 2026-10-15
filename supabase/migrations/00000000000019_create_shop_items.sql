-- Migration: 00000000000019_create_shop_items.sql
-- Description: Create shop_items and shop_purchases tables for SomaSmart Shop Management module

CREATE TABLE IF NOT EXISTS public.shop_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_en TEXT NOT NULL,
    title_sw TEXT NOT NULL,
    desc_en TEXT,
    desc_sw TEXT,
    full_desc_en TEXT,
    full_desc_sw TEXT,
    category TEXT DEFAULT 'Books',
    tags TEXT[] DEFAULT '{}',
    cover_image TEXT,
    gallery_images TEXT[] DEFAULT '{}',
    
    -- Pricing
    price NUMERIC(12, 2) NOT NULL DEFAULT 0,
    discount_price NUMERIC(12, 2),
    currency TEXT DEFAULT 'TZS',
    is_free BOOLEAN DEFAULT FALSE,

    -- Visibility & Status
    status TEXT DEFAULT 'published', -- 'published', 'draft', 'hidden'
    is_archived BOOLEAN DEFAULT FALSE,
    display_priority INT DEFAULT 0,
    publish_date TIMESTAMPTZ DEFAULT NOW(),
    expiration_date TIMESTAMPTZ,

    -- Stock / Inventory
    stock_quantity INT DEFAULT 100,
    low_stock_threshold INT DEFAULT 5,

    -- Admin-Controlled Badges
    is_featured BOOLEAN DEFAULT FALSE,
    is_recommended BOOLEAN DEFAULT FALSE,
    is_editors_choice BOOLEAN DEFAULT FALSE,
    is_on_sale BOOLEAN DEFAULT FALSE,
    is_staff_pick BOOLEAN DEFAULT FALSE,

    -- Analytics Counters
    total_purchases INT DEFAULT 0,
    total_downloads INT DEFAULT 0,
    total_views INT DEFAULT 0,
    total_revenue NUMERIC(12, 2) DEFAULT 0,
    average_rating NUMERIC(3, 2) DEFAULT 5.0,
    review_count INT DEFAULT 0,
    wishlist_count INT DEFAULT 0,
    last_purchase_at TIMESTAMPTZ,
    last_viewed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies for shop_items
ALTER TABLE public.shop_items ENABLE ROW LEVEL SECURITY;

-- Everyone can read published shop items
CREATE POLICY "Allow public read access to shop items"
ON public.shop_items FOR SELECT
USING (true);

-- Admins can manage shop items
CREATE POLICY "Allow admin full management of shop items"
ON public.shop_items FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- Table for tracking user purchases (unlocked status persistence)
CREATE TABLE IF NOT EXISTS public.shop_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES public.shop_items(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, item_id)
);

ALTER TABLE public.shop_purchases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow users to view own shop purchases"
ON public.shop_purchases FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Allow users to record own shop purchases"
ON public.shop_purchases FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow admin to view all shop purchases"
ON public.shop_purchases FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);
