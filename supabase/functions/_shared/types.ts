// Supabase Edge Functions: Shared TypeScript Domain Types
// File: supabase/functions/_shared/types.ts

export interface PlantCandidate {
  scientific_name: string;
  common_name: string | null;
  family: string | null;
  score: number;
}

export interface PlantIdentificationResult {
  status: 'identified' | 'uncertain' | 'failed';
  is_demo: boolean;
  candidates: PlantCandidate[];
  error?: string;
}

export interface EducationalContent {
  introduction: string;
  description: string;
  fun_facts: string[];
  observation_tips: string[];
  safety_note: string | null;
}

export interface SpeciesContentResponse {
  status: 'success' | 'demo' | 'error';
  scientific_name: string;
  common_name: string | null;
  family: string | null;
  language: string;
  cached: boolean;
  is_demo: boolean;
  data: EducationalContent;
  error?: string;
}

export interface VerificationCriteria {
  type:
    | 'color_match'
    | 'family_match'
    | 'morphology'
    | 'plant_type'
    | 'family_diversity'
    | 'herb_medicinal'
    | 'general';
  colors?: string[];
  family?: string;
  synonyms?: string[];
  growth_forms?: string[];
  target_feature?: string;
  required_count?: number;
  required_unique_families?: number;
  keywords?: string[];
  description?: string;
}

export interface Mission {
  id?: string;
  title: string;
  description: string;
  category: 'daily' | 'general' | 'special';
  difficulty: 'easy' | 'medium' | 'hard';
  reward_points: number;
  verification_criteria: VerificationCriteria;
  is_active?: boolean;
}

export interface Profile {
  id: string;
  username: string;
  avatar_url: string | null;
  total_points: number;
  explorer_level: number;
  created_at: string;
  updated_at: string;
}
