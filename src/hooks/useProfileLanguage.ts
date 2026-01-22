import { useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '@/integrations/supabase/client';
import { useAuthSession } from './useAuthSession';

/**
 * Hook to sync user's profile language preference with i18n
 * Loads the user's saved language preference on mount
 */
export const useProfileLanguage = () => {
  const { i18n } = useTranslation();
  const { user, loading } = useAuthSession();

  useEffect(() => {
    if (loading || !user) return;

    const loadLanguagePreference = async () => {
      try {
        const { data } = await supabase
          .from('profiles')
          .select('language_preference')
          .eq('user_id', user.id)
          .single();

        if (data?.language_preference && data.language_preference !== i18n.language) {
          await i18n.changeLanguage(data.language_preference);
        }
      } catch (error) {
        console.error('Error loading language preference:', error);
      }
    };

    loadLanguagePreference();
  }, [user, loading, i18n]);
};
