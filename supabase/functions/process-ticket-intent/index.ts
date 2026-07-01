import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { message, role, history = [], locale = 'en' } = await req.json()

    // Use the API key provided by the user, or fallback to environment variables
    const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') || 'c0697d62ed294c88b7d577a9dd8aed14.RvawMHK60MhAS3GPl1RgZuV7'
    if (!GEMINI_API_KEY) {
      throw new Error('GEMINI_API_KEY is not set.')
    }

    // Build the system prompt
    // We define departments, filieres, and ticket types based on roles
    const systemPrompt = `You are an AI assistant for the SEASAME Assist-Pro university ticketing system.
Your job is to help users draft a support ticket based on their request.
You speak in the user's preferred language (Locale: ${locale}).

Available Departments:
- "uniteIT": Unité IT (Information Technology / IT Issues)
- "uniteFinance": Unité Finance (Finance / Accounting)
- "uniteStage": Unité Stage (Internships)
- "uniteScolarite": Unité Scolarité (Student Affairs / Academics)
- "uniteMarketing": Unité Marketing (Marketing)
- "uniteRH": Unité RH (Human Resources / HR)
- "uniteCertification": Unité Certification (Certifications)
- "deptBusiness": Département Business
- "deptINGPREPA": Département ING-PREPA (Engineering Preparatory)
- "deptTA": Département TA
- "deptLIM": Département LIM

Available Priorities: "low", "medium", "high"

User Role: ${role}
Available Ticket Types for this role:
${role === 'teacher' ? 
'- classroom_it (Classroom IT)\n- hr_request (HR Request)\n- facility (Facility)\n- it_issue (IT Issue)' : 
'- academic (Academic)\n- it_issue (IT Issue)\n- facility (Facility)\n- hr_request (HR Request)'}

Instructions:
1. Analyze the user's message and history.
2. If the request is too vague to draft a ticket, set "is_clarifying" to true and provide a "clarifying_question".
3. If you have enough information, set "is_clarifying" to false and provide the "draft" object.
4. Ensure department_id, filiere_id (optional), ticket_type, and priority strictly match the allowed values.
`

    const responseSchema = {
      type: "OBJECT",
      properties: {
        is_clarifying: {
          type: "BOOLEAN",
          description: "True if you need more information to draft the ticket."
        },
        clarifying_question: {
          type: "STRING",
          description: "A question to the user if you need more details. Null if not clarifying."
        },
        draft: {
          type: "OBJECT",
          description: "The drafted ticket fields if enough information is provided. Null if clarifying.",
          properties: {
            title: { type: "STRING" },
            description: { type: "STRING" },
            ticket_type: { type: "STRING" },
            priority: { type: "STRING", description: "low, medium, or high" },
            department_id: { type: "STRING", description: "The exact department code from the list above, e.g. 'uniteIT' or 'uniteRH'" },
            filiere_id: { type: "STRING", description: "The filiere code if applicable, or null." }
          },
          required: ["title", "description", "ticket_type", "priority", "department_id"]
        }
      },
      required: ["is_clarifying"]
    }

    const geminiPayload = {
      system_instruction: {
        parts: [{ text: systemPrompt }]
      },
      contents: [
        ...history,
        { role: "user", parts: [{ text: message }] }
      ],
      generationConfig: {
        response_mime_type: "application/json",
        response_schema: responseSchema,
        temperature: 0.2
      }
    }

    const geminiResponse = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(geminiPayload)
    })

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text()
      throw new Error(`Gemini API Error: ${errorText}`)
    }

    const data = await geminiResponse.json()
    const contentText = data.candidates?.[0]?.content?.parts?.[0]?.text
    
    if (!contentText) {
      throw new Error('Failed to parse Gemini response')
    }

    const parsedContent = JSON.parse(contentText)

    return new Response(
      JSON.stringify(parsedContent),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
