return {
  -- Local service endpoint (no API key needed here!)
  SERVICE_URL = "http://localhost:3456",
  
  -- Default analysis types
  PROMPT_TYPES = {
    alt_text = "Alt Text (Accessibility)",
    keywords = "Keywords (Search)",
    caption = "Caption",
    detailed = "Detailed Analysis"
  },
  
  -- Default metadata fields
  METADATA_FIELDS = {
    alt_text = "caption",
    keywords = "keywords",
    caption = "headline"
  }
}
