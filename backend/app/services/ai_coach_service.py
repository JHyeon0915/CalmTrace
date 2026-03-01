import os
from typing import List, Dict, Optional
from datetime import datetime, timezone
from pydantic import BaseModel
from google import genai
from google.genai import types

# Get API key
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# Initialize client
client = None
if GEMINI_API_KEY:
    client = genai.Client(api_key=GEMINI_API_KEY)
    print("✅ [AICoach] Gemini client initialized")
else:
    print("⚠️ [AICoach] GEMINI_API_KEY not set")


class ChatMessage(BaseModel):
    role: str  # "user" or "assistant"
    content: str


class AICoachService:
    """
    AI Stress Coach service using Google Gemini API (google-genai package).
    
    Free tier: 15 RPM, 1M tokens/month
    """
    
    SYSTEM_PROMPT = """You are a compassionate and supportive AI stress coach in a mental wellness app called CalmTrace. Your role is to help users manage stress and anxiety through evidence-based techniques.

## Your Personality:
- Warm, empathetic, and non-judgmental
- Supportive but not overly cheerful
- Professional yet approachable
- Patient and understanding

## Your Capabilities:
1. **Breathing Exercises**: Guide users through techniques like 4-7-8 breathing, box breathing, diaphragmatic breathing
2. **Grounding Techniques**: 5-4-3-2-1 sensory technique, body scan, progressive muscle relaxation
3. **Cognitive Reframing**: Help identify negative thought patterns and reframe them
4. **Mindfulness**: Present-moment awareness, acceptance, non-judgment
5. **Emotional Validation**: Acknowledge feelings without trying to immediately fix them
6. **Stress Education**: Explain how stress affects the body and mind
7. **Sleep Hygiene**: Tips for better sleep when stress affects rest
8. **Self-Care Suggestions**: Gentle reminders about basic wellness

## Guidelines:
- Keep responses concise (2-4 sentences typically, unless guiding an exercise)
- Ask one question at a time
- Never diagnose or provide medical advice
- If someone mentions self-harm, crisis, or severe symptoms, gently suggest professional help
- Use simple, accessible language
- Offer specific, actionable techniques when appropriate
- Remember context from the conversation

## Response Style:
- Start with validation or acknowledgment when appropriate
- Be specific rather than generic
- End with a gentle question or invitation to continue (not always, use judgment)
- Use occasional emoji sparingly (💚, 🌱, ✨) but don't overdo it

## Handling Off-Topic Requests:
When users ask about things unrelated to stress, mental wellness, or emotional support (like recipes, coding, math, trivia, writing tasks, general knowledge), respond warmly but redirect:

Example responses for off-topic requests:
- "I appreciate you chatting with me! While I can't help with that, I'm here for anything stress or wellness related. How are you feeling today?"
- "That's outside my expertise as a stress coach, but I'd love to help if you're feeling overwhelmed or need some relaxation techniques!"
- "I'm specially trained for stress support rather than general questions. Is there anything on your mind that's been causing you stress lately?"

Keep redirections brief (1-2 sentences), friendly, and non-judgmental. Don't lecture - just gently steer back to wellness topics.

## Important Boundaries:
- You are NOT a replacement for therapy or medical treatment
- You cannot diagnose conditions
- You ONLY help with: stress, anxiety, relaxation, emotional support, mental wellness, sleep issues related to stress, and self-care
- You do NOT help with: recipes, coding, homework, math, general knowledge, creative writing, trivia, or any non-wellness topics
- For crisis situations, recommend: "If you're in crisis, please reach out to a mental health professional or crisis helpline"

Remember: Your goal is to help users feel heard, supported, and equipped with practical tools for managing everyday stress. Stay focused on this mission while being warm and approachable."""

    MODEL_NAME = "gemini-2.5-flash"

    def __init__(self):
        self._initialized = client is not None
        if self._initialized:
            print(f"✅ [AICoach] Service ready with model: {self.MODEL_NAME}")
        else:
            print("⚠️ [AICoach] Service not available - no API key")
    
    @property
    def is_available(self) -> bool:
        return self._initialized
    
    async def chat(
        self,
        user_message: str,
        conversation_history: Optional[List[ChatMessage]] = None,
        user_context: Optional[Dict] = None,
    ) -> Dict:
        """
        Send a message to the AI coach and get a response.
        """
        if not self.is_available:
            return {
                "success": False,
                "error": "AI Coach is not available. Please check API configuration.",
                "response": None,
            }
        
        try:
            # Build the full prompt
            full_prompt = self._format_prompt(
                user_message,
                conversation_history or [],
                user_context,
            )
            
            print(f"📤 [AICoach] Sending message ({len(full_prompt)} chars)")
            
            # Call Gemini API
            response = client.models.generate_content(
                model=self.MODEL_NAME,
                contents=full_prompt,
                config=types.GenerateContentConfig(
                    temperature=0.7,
                    top_p=0.9,
                    top_k=40,
                    max_output_tokens=1024,
                    safety_settings=[
                        types.SafetySetting(
                            category="HARM_CATEGORY_HARASSMENT",
                            threshold="BLOCK_MEDIUM_AND_ABOVE"
                        ),
                        types.SafetySetting(
                            category="HARM_CATEGORY_HATE_SPEECH",
                            threshold="BLOCK_MEDIUM_AND_ABOVE"
                        ),
                        types.SafetySetting(
                            category="HARM_CATEGORY_SEXUALLY_EXPLICIT",
                            threshold="BLOCK_MEDIUM_AND_ABOVE"
                        ),
                        types.SafetySetting(
                            category="HARM_CATEGORY_DANGEROUS_CONTENT",
                            threshold="BLOCK_MEDIUM_AND_ABOVE"
                        ),
                    ],
                ),
            )
            
            response_text = response.text.strip() if response.text else ""
            
            print(f"📥 [AICoach] Received response ({len(response_text)} chars)")
            
            # Check for empty response (safety block)
            if not response_text:
                return {
                    "success": False,
                    "error": "Response was blocked by safety filters.",
                    "response": "I want to make sure I provide helpful support. Could you tell me more about what you're experiencing?",
                }
            
            return {
                "success": True,
                "response": response_text,
                "model": self.MODEL_NAME,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
            
        except Exception as e:
            print(f"❌ [AICoach] Error: {e}")
            import traceback
            traceback.print_exc()
            return {
                "success": False,
                "error": str(e),
                "response": "I'm having trouble responding right now. Let's try again - what's on your mind?",
            }
    
    def _format_prompt(
        self,
        user_message: str,
        history: List[ChatMessage],
        user_context: Optional[Dict],
    ) -> str:
        """Format the full prompt with system instructions and context."""
        prompt_parts = [self.SYSTEM_PROMPT]
        
        # Add user context if available
        if user_context:
            context_str = "\n## Current User Context:\n"
            if "stress_level" in user_context:
                context_str += f"- Current stress level: {user_context['stress_level']}/100\n"
            if "recent_activities" in user_context:
                context_str += f"- Recent activities: {', '.join(user_context['recent_activities'])}\n"
            if "time_of_day" in user_context:
                context_str += f"- Time of day: {user_context['time_of_day']}\n"
            prompt_parts.append(context_str)
        
        # Add conversation history (last 10 messages)
        if history:
            prompt_parts.append("\n## Conversation History:")
            for msg in history[-10:]:
                role_label = "User" if msg.role == "user" else "Coach"
                prompt_parts.append(f"{role_label}: {msg.content}")
        
        # Add current message
        prompt_parts.append(f"\n## Current Message:\nUser: {user_message}")
        prompt_parts.append("\n## Your Response (as the stress coach):")
        
        return "\n".join(prompt_parts)
    
    def get_greeting(self, user_name: Optional[str] = None) -> str:
        """Get initial greeting message."""
        if user_name:
            return f"Hi {user_name}, I'm your stress support coach. I'm here to help you explore techniques that might work for you. How are you feeling right now?"
        return "Hello, I'm your stress support coach. I'm here to help you explore techniques that might work for you. What would you like to try today?"
    
    def get_quick_responses(self) -> List[Dict]:
        """Get suggested quick response options."""
        return [
            {
                "id": "breathing",
                "label": "Breathing Exercise",
                "message": "I'd like to try a breathing exercise",
            },
            {
                "id": "grounding",
                "label": "Grounding Technique",
                "message": "Can you guide me through a grounding technique?",
            },
            {
                "id": "talk",
                "label": "Just Talk",
                "message": "I just need someone to talk to",
            },
            {
                "id": "stressed",
                "label": "Feeling Stressed",
                "message": "I'm feeling really stressed right now",
            },
        ]


# Global service instance
_ai_coach_service: Optional[AICoachService] = None


def get_ai_coach_service() -> AICoachService:
    """Get or create the global AI coach service instance."""
    global _ai_coach_service
    if _ai_coach_service is None:
        _ai_coach_service = AICoachService()
    return _ai_coach_service
