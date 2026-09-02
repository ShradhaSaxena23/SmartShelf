const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/* ==========================================================================
   SECRETS
   ========================================================================== */

const SERP_API_KEY = defineSecret("SERP_API_KEY");
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

/* ==========================================================================
   GEMINI MODELS
   ========================================================================== */

const GEMINI_EXTRACTION_MODEL = "gemini-3.5-flash-lite";

const GEMINI_DONATION_MODEL = "gemini-3.5-flash";

/* ==========================================================================
   FIREBASE AUTHENTICATION
   ========================================================================== */

async function verifyFirebaseUser(req) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    const error = new Error("Authentication required.");
    error.statusCode = 401;
    throw error;
  }

  const idToken = authHeader.substring(7).trim();

  if (!idToken) {
    const error = new Error("Missing Firebase ID token.");
    error.statusCode = 401;
    throw error;
  }

  try {
    return await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    console.error("Firebase token verification failed:", error);

    const authError = new Error(
      "Invalid or expired authentication token."
    );

    authError.statusCode = 401;

    throw authError;
  }
}

/* ==========================================================================
   LOCATION NORMALIZATION
   ========================================================================== */

function normalizeLocation(location) {
  if (!location) {
    return null;
  }

  if (typeof location === "string") {
    const value = location.trim();

    return value.length > 0 ? value : null;
  }

  if (typeof location === "object") {
    const parts = [
      location.address,
      location.city,
      location.state,
      location.country,
      location.pincode,
      location.postalCode,
    ]
      .filter(
        (value) =>
          value !== null &&
          value !== undefined &&
          String(value).trim().length > 0
      )
      .map((value) => String(value).trim());

    if (parts.length > 0) {
      return [...new Set(parts)].join(", ");
    }
  }

  return null;
}

/* ==========================================================================
   SERP API
   ========================================================================== */

async function callSerpApi(params) {
  const url = new URL("https://serpapi.com/search");

  const queryParams = {
    ...params,
    api_key: SERP_API_KEY.value(),
    output: "json",
  };

  Object.entries(queryParams).forEach(([key, value]) => {
    if (
      value !== null &&
      value !== undefined &&
      String(value).trim() !== ""
    ) {
      url.searchParams.append(key, String(value));
    }
  });

  console.log("SerpApi request:", params.engine, params.q);

  const controller = new AbortController();

  const timeout = setTimeout(() => {
    controller.abort();
  }, 15000);

  let response;

  try {
    response = await fetch(url.toString(), {
      signal: controller.signal,
    });
  } catch (error) {
    if (error.name === "AbortError") {
      throw new Error(
        "SerpAPI request timed out after 15 seconds."
      );
    }

    throw error;
  } finally {
    clearTimeout(timeout);
  }

  const responseText = await response.text();

  if (!response.ok) {
    throw new Error(
      `SerpAPI request failed: ${response.status} ${responseText}`
    );
  }

  let data;

  try {
    data = JSON.parse(responseText);
  } catch (error) {
    throw new Error(
      "SerpAPI returned an invalid JSON response."
    );
  }

  if (data.error) {
    throw new Error(`SerpAPI error: ${data.error}`);
  }

  return data;
}

/* ==========================================================================
   EVENT HELPERS
   ========================================================================== */

function isPotentialEventResult(result) {
  const text = [
    result.title,
    result.snippet,
    result.displayed_link,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  const eventKeywords = [
    "event",
    "festival",
    "fair",
    "mela",
    "exhibition",
    "expo",
    "conference",
    "workshop",
    "market",
    "bazaar",
    "carnival",
    "celebration",
    "food fest",
    "food festival",
    "community",
    "trade fair",
    "trade show",
    "seminar",
    "meetup",
  ];

  return eventKeywords.some((keyword) =>
    text.includes(keyword)
  );
}

function detectEventCategory(text) {
  const value = text.toLowerCase();

  if (
    value.includes("food festival") ||
    value.includes("food fest") ||
    value.includes("food expo")
  ) {
    return "Food Festival";
  }

  if (
    value.includes("exhibition") ||
    value.includes("expo")
  ) {
    return "Exhibition";
  }

  if (
    value.includes("fair") ||
    value.includes("mela")
  ) {
    return "Fair / Mela";
  }

  if (
    value.includes("market") ||
    value.includes("bazaar")
  ) {
    return "Market";
  }

  if (
    value.includes("conference") ||
    value.includes("seminar")
  ) {
    return "Conference";
  }

  if (value.includes("workshop")) {
    return "Workshop";
  }

  if (
    value.includes("community") ||
    value.includes("celebration")
  ) {
    return "Community Event";
  }

  return "Local Event";
}

function extractDateFromText(text) {
  if (!text) {
    return null;
  }

  const datePatterns = [
    /\b\d{1,2}\s+(?:Jan|January|Feb|February|Mar|March|Apr|April|May|Jun|June|Jul|July|Aug|August|Sep|September|Oct|October|Nov|November|Dec|December)\s+\d{4}\b/i,

    /\b(?:Jan|January|Feb|February|Mar|March|Apr|April|May|Jun|June|Jul|July|Aug|August|Sep|September|Oct|October|Nov|November|Dec|December)\s+\d{1,2},?\s+\d{4}\b/i,

    /\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b/,

    /\b\d{1,2}\s*-\s*\d{1,2}\s+(?:Jan|January|Feb|February|Mar|March|Apr|April|May|Jun|June|Jul|July|Aug|August|Sep|September|Oct|October|Nov|November|Dec|December)\b/i,

    /\b(?:this|next)\s+(?:week|weekend|month)\b/i,
  ];

  for (const pattern of datePatterns) {
    const match = text.match(pattern);

    if (match) {
      return match[0];
    }
  }

  return null;
}

function extractVenue(title, snippet) {
  const text = `${title} ${snippet}`;

  const venuePatterns = [
    /at\s+([^.,|]+(?:Convention|Centre|Center|Hall|Ground|Stadium|Park|Hotel|Mall)[^.,|]*)/i,

    /held at\s+([^.,|]+)/i,

    /venue[:\s]+([^.,|]+)/i,
  ];

  for (const pattern of venuePatterns) {
    const match = text.match(pattern);

    if (match && match[1]) {
      return match[1].trim();
    }
  }

  return "See event details";
}

function normalizeEvent(result, index, query) {
  return {
    id:
      result.link ||
      `event_${index}`,

    name:
      result.title ||
      "Local Event",

    category:
      detectEventCategory(
        `${result.title || ""} ${result.snippet || ""}`
      ),

    dateText:
      result.date ||
      extractDateFromText(result.snippet || "") ||
      "Date not available",

    venue:
      extractVenue(
        result.title || "",
        result.snippet || ""
      ),

    address: "",

    description:
      result.snippet ||
      "Local event that may provide a sales opportunity.",

    link:
      result.link ||
      "",

    imageUrl:
      result.thumbnail ||
      null,

    source:
      result.source ||
      "",

    query,
  };
}

/* ==========================================================================
   ORGANIZATION HELPERS
   ========================================================================== */

function detectOrganizationCategory(text) {
  const value = text.toLowerCase();

  if (
    value.includes("animal shelter") ||
    value.includes("animal rescue") ||
    value.includes("gaushala") ||
    value.includes("animal welfare")
  ) {
    return "Animal Shelter";
  }

  if (
    value.includes("food bank") ||
    value.includes("foodbank")
  ) {
    return "Food Bank";
  }

  if (
    value.includes("midday meal") ||
    value.includes("mid day meal")
  ) {
    return "Midday Meal";
  }

  if (
    value.includes("ngo") ||
    value.includes("foundation") ||
    value.includes("charity") ||
    value.includes("trust")
  ) {
    return "NGO / Charity";
  }

  if (
    value.includes("community kitchen") ||
    value.includes("kitchen")
  ) {
    return "Community Kitchen";
  }

  if (value.includes("shelter")) {
    return "Shelter";
  }

  return "Local Organization";
}

function buildGoogleMapsUrl(query) {
  return (
    "https://www.google.com/maps/search/?api=1&query=" +
    encodeURIComponent(query)
  );
}

function normalizeOrganization(result, index) {
  const text = [
    result.title,
    result.snippet,
  ]
    .filter(Boolean)
    .join(" ");

  return {
    id:
      result.link ||
      `organization_${index}`,

    name:
      result.title ||
      "Local Organization",

    category:
      detectOrganizationCategory(text),

    address: "",

    phone: null,

    operatingHours: null,

    rating: null,

    reviews: null,

    description:
      result.snippet ||
      "",

    mapsUrl:
      buildGoogleMapsUrl(
        result.title || ""
      ),

    website:
      result.link ||
      null,

    thumbnail:
      result.thumbnail ||
      null,
  };
}

/* ==========================================================================
   DEDUPLICATION
   ========================================================================== */

function deduplicateResults(results) {
  const seen = new Set();

  return results.filter((item) => {
    const key =
      item.link ||
      item.name?.toLowerCase().trim();

    if (!key) {
      return false;
    }

    if (seen.has(key)) {
      return false;
    }

    seen.add(key);

    return true;
  });
}

/* ==========================================================================
   SEARCH SERP CLOUD FUNCTION
   ========================================================================== */

exports.searchSerp = onRequest(
  {
    region: "asia-south2",
    secrets: [SERP_API_KEY],
    cors: true,
    timeoutSeconds: 60,
    memory: "256MiB",
  },

  async (req, res) => {
    try {
      res.set(
        "Access-Control-Allow-Origin",
        "*"
      );

      res.set(
        "Access-Control-Allow-Headers",
        "Authorization, Content-Type"
      );

      res.set(
        "Access-Control-Allow-Methods",
        "GET, OPTIONS"
      );

      if (req.method === "OPTIONS") {
        return res.status(204).send("");
      }

      if (req.method !== "GET") {
        return res.status(405).json({
          success: false,
          error: "Method not allowed. Use GET.",
        });
      }

      const decodedToken =
        await verifyFirebaseUser(req);

      const uid =
        decodedToken.uid;

      const userDoc =
        await db
          .collection("users")
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        return res.status(404).json({
          success: false,
          error: "User profile not found.",
        });
      }

      const userData =
        userDoc.data() || {};

      const location =
        normalizeLocation(
          userData.location
        );

      if (!location) {
        return res.status(400).json({
          success: false,
          error:
            "No location is saved for this user. Please add your location first.",
        });
      }

      console.log(
        `Searching Google results for location: ${location}`
      );

      /* --------------------------------------------------------------------
         EVENTS
         -------------------------------------------------------------------- */

      const eventQueries = [
        `upcoming events festivals fairs exhibitions in ${location} 2026`,
        `food festivals markets exhibitions in ${location} 2026`,
        `community events conferences workshops in ${location} 2026`,
      ];

      const eventSearchPromises =
        eventQueries.map(async (query) => {
          try {
            const data =
              await callSerpApi({
                engine: "google",
                q: query,
                location,
                google_domain: "google.com",
                gl: "in",
                hl: "en",
                device: "desktop",
                num: 10,
                safe: "active",
              });

            const organicResults =
              Array.isArray(
                data.organic_results
              )
                ? data.organic_results
                : [];

            return organicResults
              .filter((result) =>
                isPotentialEventResult(result)
              )
              .map((result, index) =>
                normalizeEvent(
                  result,
                  index,
                  query
                )
              );
          } catch (error) {
            console.error(
              `Event search failed for "${query}":`,
              error
            );

            return [];
          }
        });

      const eventSearchResults =
        await Promise.all(
          eventSearchPromises
        );

      const events =
        deduplicateResults(
          eventSearchResults.flat()
        ).slice(0, 20);

      /* --------------------------------------------------------------------
         ORGANIZATIONS
         -------------------------------------------------------------------- */

      const organizationQueries = [
        `NGOs food banks community kitchens in ${location}`,
      ];

      const organizationSearchPromises =
        organizationQueries.map(async (query) => {
          try {
            const data =
              await callSerpApi({
                engine: "google",
                q: query,
                location,
                google_domain: "google.com",
                gl: "in",
                hl: "en",
                device: "desktop",
                num: 10,
                safe: "active",
              });

            const organicResults =
              Array.isArray(
                data.organic_results
              )
                ? data.organic_results
                : [];

            return organicResults.map(
              (result, index) =>
                normalizeOrganization(
                  result,
                  index
                )
            );
          } catch (error) {
            console.error(
              `Organization search failed for "${query}":`,
              error
            );

            return [];
          }
        });

      const organizationSearchResults =
        await Promise.all(
          organizationSearchPromises
        );

      const organizations =
        deduplicateResults(
          organizationSearchResults.flat()
        ).slice(0, 20);

      return res.status(200).json({
        success: true,
        location,
        events,
        organizations,
      });
    } catch (error) {
      console.error(
        "Sale Ideas error:",
        error
      );

      const statusCode =
        error.statusCode &&
        Number.isInteger(
          error.statusCode
        )
          ? error.statusCode
          : 500;

      return res.status(statusCode).json({
        success: false,
        error:
          error.message ||
          "Something went wrong while finding local opportunities.",
      });
    }
  }
);

/* ==========================================================================
   GEMINI PRODUCT EXTRACTION
   ========================================================================== */

const GEMINI_EXTRACTION_PROMPT = `
You are SmartShelf's product packaging extraction engine.

Analyze the provided product/package image carefully.

Your job is to READ ONLY information that is visibly printed on the package.

Return exactly one JSON object.

Required JSON structure:

{
  "productName": "",
  "brand": "",
  "category": "",
  "quantitySize": "",
  "originalPrice": 0,
  "batchNumber": "",
  "expiryDate": ""
}

CATEGORY MUST BE ONE OF:

Dairy & Eggs
Bakery & Bread
Fruits & Vegetables
Meat & Seafood
Beverages
Pantry & Staples
Snacks & Confectionery
Frozen Foods
Personal Care
Household Items
Other

IMPORTANT EXTRACTION RULES:

1. PRODUCT NAME
Read the actual product name printed on the package.

2. BRAND
Read the visible brand name.

3. CATEGORY
Choose the closest category from the allowed list.

4. QUANTITY / SIZE
Look for:
- Net Weight
- Net Qty
- Net Quantity
- Volume
- Weight
- ml
- L
- g
- kg
- pcs

Examples:
"500 g"
"1 kg"
"200 ml"
"1 L"

5. PRICE
Look specifically for:
- MRP
- Maximum Retail Price
- ₹
- Rs.
- INR

Return ONLY the numeric value.

Example:
"MRP ₹85" -> 85

If no price is clearly visible:
0

6. BATCH NUMBER
Look for:
- Batch No
- Batch Number
- Batch
- Lot No
- Lot Number
- LOT

Return the visible identifier.

7. EXPIRY DATE
Look for:
- EXP
- EXPIRY
- EXP DATE
- USE BY
- BEST BEFORE

IMPORTANT:

Do NOT confuse:
- MFD
- MFG
- MANUFACTURED
- PACKED ON

with expiry.

If the package says:

"Best Before 6 Months From MFD"

and the manufacturing date is clearly visible,
you may calculate the resulting date.

Otherwise return an empty string.

If a clear expiry date is visible, convert it to:

YYYY-MM-DD

8. DATE FORMAT

Examples:

"EXP 15/08/2026"
-> "2026-08-15"

"EXP 08/2026"
-> "2026-08-31"

"Best Before: Aug 2026"
-> "2026-08-31"

If only month/year is visible, use the last day of that month.

9. DO NOT GUESS.

If something is not readable or not visible:
return an empty string.

10. DO NOT infer the product from visual appearance alone when the text
cannot be read.

11. Return ONLY JSON.

12. Do not use Markdown.

13. Do not include explanations.

14. Do not include additional fields.
`;

/* ==========================================================================
   GEMINI JSON SCHEMA
   ========================================================================== */

const GEMINI_PRODUCT_SCHEMA = {
  type: "OBJECT",

  properties: {
    productName: {
      type: "STRING",
    },

    brand: {
      type: "STRING",
    },

    category: {
      type: "STRING",
      enum: [
        "Dairy & Eggs",
        "Bakery & Bread",
        "Fruits & Vegetables",
        "Meat & Seafood",
        "Beverages",
        "Pantry & Staples",
        "Snacks & Confectionery",
        "Frozen Foods",
        "Personal Care",
        "Household Items",
        "Other",
      ],
    },

    quantitySize: {
      type: "STRING",
    },

    originalPrice: {
      type: "NUMBER",
    },

    batchNumber: {
      type: "STRING",
    },

    expiryDate: {
      type: "STRING",
    },
  },

  required: [
    "productName",
    "brand",
    "category",
    "quantitySize",
    "originalPrice",
    "batchNumber",
    "expiryDate",
  ],
};

/* ==========================================================================
   BASE64 CLEANING
   ========================================================================== */

function cleanBase64Image(imageBase64) {
  let value = imageBase64.trim();

  if (value.includes(",")) {
    const possiblePrefix =
      value.substring(
        0,
        value.indexOf(",")
      );

    if (
      possiblePrefix
        .toLowerCase()
        .includes("base64")
    ) {
      value =
        value.substring(
          value.indexOf(",") + 1
        );
    }
  }

  value =
    value.replace(/\s/g, "");

  return value;
}

/* ==========================================================================
   BASE64 VALIDATION
   ========================================================================== */

function validateBase64(base64) {
  if (!base64 || base64.length === 0) {
    return false;
  }

  const validCharacters =
    /^[A-Za-z0-9+/]*={0,2}$/;

  return validCharacters.test(base64);
}

/* ==========================================================================
   GEMINI PRODUCT EXTRACTION FUNCTION
   ========================================================================== */

exports.extractGemini = onRequest(
  {
    region: "asia-south2",
    secrets: [GEMINI_API_KEY],
    cors: true,
    timeoutSeconds: 60,
    memory: "512MiB",
    maxInstances: 3,
  },

  async (req, res) => {
    try {
      res.set(
        "Access-Control-Allow-Origin",
        "*"
      );

      res.set(
        "Access-Control-Allow-Headers",
        "Authorization, Content-Type"
      );

      res.set(
        "Access-Control-Allow-Methods",
        "POST, OPTIONS"
      );

      if (req.method === "OPTIONS") {
        return res.status(204).send("");
      }

      if (req.method !== "POST") {
        return res.status(405).json({
          success: false,
          error: "Method not allowed. Use POST.",
        });
      }

      const decodedToken =
        await verifyFirebaseUser(req);

      console.log(
        "Gemini extraction requested by:",
        decodedToken.uid
      );

      const body =
        req.body || {};

      let imageBase64 =
        body.imageBase64;

      const mimeType =
        typeof body.mimeType === "string" &&
        body.mimeType.startsWith("image/")
          ? body.mimeType
          : "image/jpeg";

      if (
        typeof imageBase64 !== "string" ||
        imageBase64.trim().length === 0
      ) {
        return res.status(400).json({
          success: false,
          error:
            "imageBase64 is required.",
        });
      }

      imageBase64 =
        cleanBase64Image(
          imageBase64
        );

      if (
        !validateBase64(
          imageBase64
        )
      ) {
        console.error(
          "Invalid Base64 image data."
        );

        return res.status(400).json({
          success: false,
          error:
            "Invalid Base64 image data.",
        });
      }

      const estimatedImageBytes =
        Math.floor(
          imageBase64.length * 3 / 4
        );

      console.log(
        "----------------------------------------"
      );

      console.log(
        "GEMINI IMAGE EXTRACTION"
      );

      console.log(
        "Model:",
        GEMINI_EXTRACTION_MODEL
      );

      console.log(
        "MIME:",
        mimeType
      );

      console.log(
        "Base64 length:",
        imageBase64.length
      );

      console.log(
        "Estimated image bytes:",
        estimatedImageBytes
      );

      console.log(
        "----------------------------------------"
      );

      if (
        estimatedImageBytes >
        15 * 1024 * 1024
      ) {
        return res.status(413).json({
          success: false,
          error:
            "Image is too large. Please use an image smaller than 15 MB.",
        });
      }

      const geminiUrl =
        `https://generativelanguage.googleapis.com/v1beta/models/` +
        `${GEMINI_EXTRACTION_MODEL}:generateContent`;

      const requestBody = {
        contents: [
          {
            role: "user",

            parts: [
              {
                text:
                  GEMINI_EXTRACTION_PROMPT,
              },

              {
                inline_data: {
                  mime_type: mimeType,
                  data: imageBase64,
                },
              },
            ],
          },
        ],

        generationConfig: {
          responseMimeType:
            "application/json",

          responseSchema:
            GEMINI_PRODUCT_SCHEMA,

          thinkingConfig: {
            thinkingLevel: "low",
          },
        },
      };

      const geminiResponse =
        await fetch(
          geminiUrl,
          {
            method: "POST",

            headers: {
              "Content-Type":
                "application/json",

              "x-goog-api-key":
                GEMINI_API_KEY.value(),
            },

            body:
              JSON.stringify(
                requestBody
              ),
          }
        );

      const responseText =
        await geminiResponse.text();

      console.log(
        "Gemini HTTP status:",
        geminiResponse.status
      );

      let geminiData;

      try {
        geminiData =
          JSON.parse(
            responseText
          );
      } catch (error) {
        console.error(
          "Gemini returned invalid JSON:"
        );

        console.error(
          responseText
        );

        return res.status(502).json({
          success: false,
          error:
            "Gemini returned an invalid API response.",
        });
      }

      if (
        !geminiResponse.ok
      ) {
        console.error(
          "Gemini API ERROR:"
        );

        console.error(
          JSON.stringify(
            geminiData,
            null,
            2
          )
        );

        const apiError =
          geminiData?.error?.message ||
          "Gemini API request failed.";

        return res.status(
          geminiResponse.status ===
          429
            ? 429
            : 502
        ).json({
          success: false,
          error: apiError,
        });
      }

      const candidate =
        geminiData?.candidates?.[0];

      if (!candidate) {
        console.error(
          "Gemini returned no candidate."
        );

        console.error(
          JSON.stringify(
            geminiData,
            null,
            2
          )
        );

        return res.status(502).json({
          success: false,
          error:
            "Gemini returned no candidates.",
        });
      }

      console.log(
        "Gemini finish reason:",
        candidate.finishReason
      );

      const parts =
        candidate?.content?.parts ||
        [];

      const generatedText =
        parts
          .filter(
            (part) =>
              part &&
              typeof part.text ===
                "string"
          )
          .map(
            (part) =>
              part.text
          )
          .join("")
          .trim();

      console.log(
        "Gemini generated text:"
      );

      console.log(
        generatedText
      );

      if (!generatedText) {
        return res.status(502).json({
          success: false,
          error:
            "Gemini returned an empty extraction response.",
        });
      }

      let cleanedText =
        generatedText;

      cleanedText =
        cleanedText.replace(
          /^```json\s*/i,
          ""
        );

      cleanedText =
        cleanedText.replace(
          /^```\s*/i,
          ""
        );

      cleanedText =
        cleanedText.replace(
          /\s*```$/i,
          ""
        );

      cleanedText =
        cleanedText.trim();

      const firstBrace =
        cleanedText.indexOf("{");

      const lastBrace =
        cleanedText.lastIndexOf("}");

      if (
        firstBrace !== -1 &&
        lastBrace !== -1 &&
        lastBrace > firstBrace
      ) {
        cleanedText =
          cleanedText.substring(
            firstBrace,
            lastBrace + 1
          );
      }

      console.log(
        "Cleaned extraction JSON:"
      );

      console.log(
        cleanedText
      );

      let product;

      try {
        product =
          JSON.parse(
            cleanedText
          );
      } catch (error) {
        console.error(
          "Product JSON parsing failed."
        );

        console.error(
          "Generated text:",
          generatedText
        );

        return res.status(502).json({
          success: false,
          error:
            "Gemini returned product data in an unexpected format.",
          rawResponse:
            generatedText,
        });
      }

      if (
        !product ||
        typeof product !==
          "object" ||
        Array.isArray(product)
      ) {
        return res.status(502).json({
          success: false,
          error:
            "Gemini returned invalid product data.",
        });
      }

      let originalPrice =
        0.0;

      if (
        typeof product.originalPrice ===
        "number"
      ) {
        originalPrice =
          product.originalPrice;
      } else if (
        typeof product.originalPrice ===
        "string"
      ) {
        const cleanedPrice =
          product.originalPrice
            .replace(/[₹,\s]/g, "");

        const parsedPrice =
          Number(
            cleanedPrice
          );

        if (
          Number.isFinite(
            parsedPrice
          )
        ) {
          originalPrice =
            parsedPrice;
        }
      }

      const normalizedProduct = {
        productName:
          typeof product.productName ===
          "string"
            ? product.productName.trim()
            : "",

        brand:
          typeof product.brand ===
          "string"
            ? product.brand.trim()
            : "",

        category:
          typeof product.category ===
          "string"
            ? product.category.trim()
            : "Other",

        quantitySize:
          typeof product.quantitySize ===
          "string"
            ? product.quantitySize.trim()
            : "",

        originalPrice,

        batchNumber:
          typeof product.batchNumber ===
          "string"
            ? product.batchNumber.trim()
            : "",

        expiryDate:
          typeof product.expiryDate ===
          "string"
            ? product.expiryDate.trim()
            : "",
      };

      console.log(
        "========================================"
      );

      console.log(
        "GEMINI EXTRACTION SUCCESS"
      );

      console.log(
        JSON.stringify(
          normalizedProduct,
          null,
          2
        )
      );

      console.log(
        "========================================"
      );

      return res.status(200).json({
        success: true,

        product:
          normalizedProduct,

        usedAi: true,

        model:
          GEMINI_EXTRACTION_MODEL,
      });
    } catch (error) {
      console.error(
        "Gemini extraction function error:"
      );

      console.error(
        error
      );

      const statusCode =
        error?.statusCode &&
        Number.isInteger(
          error.statusCode
        )
          ? error.statusCode
          : 500;

      return res.status(
        statusCode
      ).json({
        success: false,

        error:
          error?.message ||
          "Something went wrong while extracting product information.",
      });
    }
  }
);

/* ==========================================================================
   DONATION SUITABILITY
   ========================================================================== */

const DONATION_CATEGORIES = [
  "human_consumption",
  "animal_feed",
  "non_food_use",
  "unsafe",
  "unknown",
];

const DONATION_ORG_TYPES = [
  "Gaushala",
  "Animal Shelter",
  "Poultry Farm",
  "Dairy Farm",
  "Cattle Shelter",
  "Food Bank",
  "Community Kitchen",
  "NGO",
];

/* ==========================================================================
   GEMINI DONATION PROMPT
   ========================================================================== */

const DONATION_SUITABILITY_PROMPT = `
You are SmartShelf's donation-safety assistant.

Analyze the grocery product information provided below and determine whether
the product could potentially be donated.

You must be conservative about food safety.

IMPORTANT:

The product's expiry status is important, but do not automatically assume
that every non-expired product is safe.

Consider:

- product type
- product category
- expiry date
- days remaining
- perishability
- possible spoilage
- mold
- contamination
- rancidity
- packaging condition
- storage requirements
- whether the product is normally suitable for humans or animals

RULES:

1. A product that has NOT expired can potentially be donated.

2. A product that expires today can potentially be donated immediately if
   its packaging, storage and physical condition are acceptable.

3. An expired product must be evaluated conservatively.

4. Never claim that an expired product is definitely safe.

5. If a product is expired, do NOT recommend it for human consumption simply
   because it is a dry food.

6. If an expired dry/bakery/grain product may potentially be redirected to
   animal feed, clearly state that the receiving organization must inspect
   the product before accepting it.

7. Consider mold, insects, contamination, unusual odor, rancidity,
   decomposition and other spoilage risks.

8. If the product could potentially be used as animal feed, suggest realistic
   animals.

9. If the product is potentially suitable for human consumption, suggest
   Food Bank, Community Kitchen or NGO.

10. If the product is potentially suitable as animal feed, suggest relevant
    organization types such as:
    - Gaushala
    - Animal Shelter
    - Poultry Farm
    - Dairy Farm
    - Cattle Shelter

11. If the product is unsafe or there is insufficient information:

    isSuitable = false

    suggestedAnimals = []

    suggestedOrgTypes = []

12. Only use these donation categories:

    human_consumption
    animal_feed
    non_food_use
    unsafe
    unknown

13. Only use these organization types:

    Gaushala
    Animal Shelter
    Poultry Farm
    Dairy Farm
    Cattle Shelter
    Food Bank
    Community Kitchen
    NGO

14. suggestedAnimals must contain realistic animal names only.

15. Do not invent information about the product.

16. Do not claim that an organization has agreed to accept the product.

17. Return ONLY JSON matching the provided schema.
`;

/* ==========================================================================
   DONATION RESPONSE SCHEMA
   ========================================================================== */

const DONATION_RESPONSE_SCHEMA = {
  type: "OBJECT",

  properties: {
    isSuitable: {
      type: "BOOLEAN",
    },

    donationCategory: {
      type: "STRING",
      enum: DONATION_CATEGORIES,
    },

    reason: {
      type: "STRING",
    },

    suggestedAnimals: {
      type: "ARRAY",

      items: {
        type: "STRING",
      },
    },

    suggestedOrgTypes: {
      type: "ARRAY",

      items: {
        type: "STRING",

        enum: DONATION_ORG_TYPES,
      },
    },
  },

  required: [
    "isSuitable",
    "donationCategory",
    "reason",
    "suggestedAnimals",
    "suggestedOrgTypes",
  ],
};

/* ==========================================================================
   EXPIRY STATUS
   ========================================================================== */

function buildExpiryStatus(daysRemaining) {
  if (daysRemaining > 0) {
    return (
      `The product has NOT expired. It expires in ${daysRemaining} ` +
      `${daysRemaining === 1 ? "day" : "days"}.`
    );
  }

  if (daysRemaining === 0) {
    return "The product expires TODAY.";
  }

  const daysExpired = Math.abs(daysRemaining);

  return (
    `The product expired ${daysExpired} ` +
    `${daysExpired === 1 ? "day" : "days"} ago.`
  );
}

/* ==========================================================================
   CATEGORY MATCHING
   ========================================================================== */

function containsAny(text, values) {
  const normalized =
    String(text || "").toLowerCase();

  return values.some((value) =>
    normalized.includes(
      value.toLowerCase()
    )
  );
}

/* ==========================================================================
   DONATION FALLBACK
   ========================================================================== */

function fallbackDonationResult(product) {
  const daysRemaining =
    product.daysRemaining;

  const category =
    String(
      product.category || ""
    ).toLowerCase();

  /* ------------------------------------------------------------------------
     FUTURE PRODUCT
     ------------------------------------------------------------------------ */

  if (daysRemaining > 0) {
    if (
      containsAny(
        category,
        [
          "grain",
          "cereal",
          "flour",
          "rice",
          "wheat",
          "bakery",
          "bread",
          "biscuit",
          "cookie",
          "cracker",
          "snack",
          "chips",
        ]
      )
    ) {
      return {
        isSuitable: true,

        donationCategory:
          "animal_feed",

        reason:
          "Gemini was unavailable. This product has not expired and may potentially be redirected to an appropriate animal-feed organization before expiry. The receiving organization should inspect it before accepting it.",

        suggestedAnimals: [
          "Cattle",
          "Goats",
          "Chickens",
          "Poultry",
        ],

        suggestedOrgTypes: [
          "Gaushala",
          "Cattle Shelter",
          "Poultry Farm",
          "Animal Shelter",
        ],
      };
    }

    if (
      containsAny(
        category,
        [
          "fruit",
          "vegetable",
          "produce",
        ]
      )
    ) {
      return {
        isSuitable: true,

        donationCategory:
          "animal_feed",

        reason:
          "This product has not expired and may potentially be donated as animal feed if it remains in acceptable condition.",

        suggestedAnimals: [
          "Cattle",
          "Goats",
          "Poultry",
        ],

        suggestedOrgTypes: [
          "Gaushala",
          "Cattle Shelter",
          "Animal Shelter",
        ],
      };
    }

    if (
      containsAny(
        category,
        [
          "dairy",
          "milk",
          "beverage",
        ]
      )
    ) {
      return {
        isSuitable: true,

        donationCategory:
          "human_consumption",

        reason:
          "This product has not expired yet and may potentially be donated for human consumption if it is unopened, properly stored, and safe.",

        suggestedAnimals: [],

        suggestedOrgTypes: [
          "Food Bank",
          "Community Kitchen",
          "NGO",
        ],
      };
    }

    return {
      isSuitable: false,

      donationCategory:
        "unknown",

      reason:
        "Gemini could not be reached, so there is not enough information to safely classify this product for donation.",

      suggestedAnimals: [],

      suggestedOrgTypes: [],
    };
  }

  /* ------------------------------------------------------------------------
     EXPIRES TODAY
     ------------------------------------------------------------------------ */

  if (daysRemaining === 0) {
    return {
      isSuitable: true,

      donationCategory:
        "human_consumption",

      reason:
        "This product expires today. It may potentially be donated immediately if its packaging, storage conditions, and physical condition are acceptable.",

      suggestedAnimals: [],

      suggestedOrgTypes: [
        "Food Bank",
        "Community Kitchen",
        "NGO",
      ],
    };
  }

  /* ------------------------------------------------------------------------
     EXPIRED PRODUCT
     ------------------------------------------------------------------------ */

  const daysExpired =
    Math.abs(daysRemaining);

  /* ------------------------------------------------------------------------
     HIGH-RISK PERISHABLE
     ------------------------------------------------------------------------ */

  if (
    containsAny(
      category,
      [
        "milk",
        "dairy",
        "meat",
        "fish",
        "seafood",
        "chicken",
        "egg",
        "eggs",
      ]
    )
  ) {
    return {
      isSuitable: false,

      donationCategory:
        "unsafe",

      reason:
        `This product has expired ${daysExpired} ` +
        `${daysExpired === 1 ? "day" : "days"} ago and belongs to a highly perishable category. Without inspection and additional safety information, it should not be recommended for donation or animal consumption.`,

      suggestedAnimals: [],

      suggestedOrgTypes: [],
    };
  }

  /* ------------------------------------------------------------------------
     BAKERY / DRY FOOD
     ------------------------------------------------------------------------ */

  if (
    containsAny(
      category,
      [
        "bakery",
        "bread",
        "biscuit",
        "cookie",
        "cracker",
        "cake",
        "pastry",
        "grain",
        "cereal",
        "flour",
        "rice",
        "wheat",
        "snack",
        "chips",
      ]
    )
  ) {
    if (daysExpired > 14) {
      return {
        isSuitable: false,

        donationCategory:
          "unsafe",

        reason:
          "This product has been expired for more than two weeks. Without reliable information about its current condition and storage, it should not be recommended for donation.",

        suggestedAnimals: [],

        suggestedOrgTypes: [],
      };
    }

    return {
      isSuitable: true,

      donationCategory:
        "animal_feed",

      reason:
        `This dry or bakery product has expired ${daysExpired} ` +
        `${daysExpired === 1 ? "day" : "days"} ago. It may potentially be repurposed as animal feed only if it has no mold, insects, contamination, unusual odor, rancidity, or other signs of spoilage. The receiving organization must make the final decision.`,

      suggestedAnimals: [
        "Cattle",
        "Goats",
        "Chickens",
        "Poultry",
      ],

      suggestedOrgTypes: [
        "Gaushala",
        "Cattle Shelter",
        "Poultry Farm",
        "Animal Shelter",
      ],
    };
  }

  /* ------------------------------------------------------------------------
     FRUITS / VEGETABLES
     ------------------------------------------------------------------------ */

  if (
    containsAny(
      category,
      [
        "fruit",
        "vegetable",
        "produce",
      ]
    )
  ) {
    if (daysExpired > 7) {
      return {
        isSuitable: false,

        donationCategory:
          "unsafe",

        reason:
          `This produce has been expired for ${daysExpired} days. Without knowing its current physical condition, it should not be recommended for donation.`,

        suggestedAnimals: [],

        suggestedOrgTypes: [],
      };
    }

    return {
      isSuitable: true,

      donationCategory:
        "animal_feed",

      reason:
        "Some expired produce may potentially be used as animal feed if it is free from mold, toxic substances, severe decomposition, and contamination. The receiving organization must inspect it before accepting it.",

      suggestedAnimals: [
        "Cattle",
        "Goats",
        "Poultry",
      ],

      suggestedOrgTypes: [
        "Gaushala",
        "Cattle Shelter",
        "Animal Shelter",
      ],
    };
  }

  /* ------------------------------------------------------------------------
     UNKNOWN
     ------------------------------------------------------------------------ */

  return {
    isSuitable: false,

    donationCategory:
      "unknown",

    reason:
      "Gemini could not be reached and there is not enough reliable information to safely determine whether this expired product can be donated.",

    suggestedAnimals: [],

    suggestedOrgTypes: [],
  };
}

/* ==========================================================================
   DONATION RESULT NORMALIZATION
   ========================================================================== */

function normalizeDonationResult(result) {
  const isSuitable =
    result?.isSuitable === true;

  const rawCategory =
    typeof result?.donationCategory ===
    "string"
      ? result.donationCategory.trim()
      : "";

  const donationCategory =
    DONATION_CATEGORIES.includes(
      rawCategory
    )
      ? rawCategory
      : "unknown";

  const rawReason =
    typeof result?.reason ===
    "string"
      ? result.reason.trim()
      : "";

  const reason =
    rawReason.length > 0
      ? rawReason
      : "Gemini did not provide a reason.";

  let suggestedAnimals = [];

  if (
    Array.isArray(
      result?.suggestedAnimals
    )
  ) {
    suggestedAnimals =
      result.suggestedAnimals
        .map((item) =>
          String(item).trim()
        )
        .filter(
          (item) =>
            item.length > 0
        );
  }

  suggestedAnimals = [
    ...new Set(
      suggestedAnimals
    ),
  ];

  let suggestedOrgTypes = [];

  if (
    Array.isArray(
      result?.suggestedOrgTypes
    )
  ) {
    suggestedOrgTypes =
      result.suggestedOrgTypes
        .map((item) =>
          String(item).trim()
        )
        .filter((item) =>
          DONATION_ORG_TYPES.includes(
            item
          )
        );
  }

  suggestedOrgTypes = [
    ...new Set(
      suggestedOrgTypes
    ),
  ];

  if (
    !isSuitable ||
    donationCategory ===
      "unsafe" ||
    donationCategory ===
      "unknown"
  ) {
    suggestedAnimals = [];
    suggestedOrgTypes = [];
  }

  const finalIsSuitable =
    isSuitable &&
    suggestedOrgTypes.length > 0;

  return {
    isSuitable:
      finalIsSuitable,

    donationCategory,

    reason,

    suggestedAnimals,

    suggestedOrgTypes,
  };
}

/* ==========================================================================
   DONATION CLOUD FUNCTION
   ========================================================================== */

/* ==========================================================================
   DONATION CLOUD FUNCTION - DEBUG VERSION
   ========================================================================== */

exports.checkDonationEligibility = onRequest(
  {
    region: "asia-south2",

    secrets: [
      GEMINI_API_KEY,SERP_API_KEY,
    ],

    cors: true,

    timeoutSeconds: 60,

    memory: "256MiB",

    maxInstances: 3,
  },

  async (req, res) => {
    /* ----------------------------------------------------------------------
       CORS
       ---------------------------------------------------------------------- */

    res.set(
      "Access-Control-Allow-Origin",
      "*"
    );

    res.set(
      "Access-Control-Allow-Headers",
      "Content-Type, Authorization"
    );

    res.set(
      "Access-Control-Allow-Methods",
      "POST, OPTIONS"
    );

    if (req.method === "OPTIONS") {
      return res.status(204).send("");
    }

    /* ----------------------------------------------------------------------
       METHOD
       ---------------------------------------------------------------------- */

    if (req.method !== "POST") {
      return res.status(405).json({
        success: false,
        error: "Method not allowed. Use POST.",
      });
    }

    /* ----------------------------------------------------------------------
       AUTH
       ---------------------------------------------------------------------- */

    let decodedToken;

    try {
      decodedToken =
        await verifyFirebaseUser(req);
    } catch (error) {
      return res.status(
        error.statusCode || 401
      ).json({
        success: false,
        error:
          error.message ||
          "Authentication failed.",
      });
    }

    try {
      /* ====================================================================
         REQUEST BODY
         ==================================================================== */

      const body =
        req.body || {};

      const productName =
        typeof body.productName === "string"
          ? body.productName.trim()
          : "";

      const productCategory =
        typeof body.productCategory === "string"
          ? body.productCategory.trim()
          : "";

      const statusCategory =
        typeof body.statusCategory === "string"
          ? body.statusCategory.trim()
          : "";

      const expiryDate =
        typeof body.expiryDate === "string"
          ? body.expiryDate.trim()
          : "";

      const brand =
        typeof body.brand === "string"
          ? body.brand.trim()
          : "";

      const quantity =
        body.quantity !== undefined &&
        body.quantity !== null
          ? String(body.quantity)
          : "";

      const daysRemaining =
        Number(body.daysRemaining);

      /* ====================================================================
         VALIDATION
         ==================================================================== */

      if (!productName) {
        return res.status(400).json({
          success: false,
          error: "productName is required.",
        });
      }

      if (!productCategory) {
        return res.status(400).json({
          success: false,
          error: "productCategory is required.",
        });
      }

      if (!expiryDate) {
        return res.status(400).json({
          success: false,
          error: "expiryDate is required.",
        });
      }

      if (!Number.isFinite(daysRemaining)) {
        return res.status(400).json({
          success: false,
          error:
            "daysRemaining must be a valid number.",
        });
      }

      /* ====================================================================
         EXPIRY STATUS
         ==================================================================== */

      const expiryStatus =
        buildExpiryStatus(
          daysRemaining
        );

      /* ====================================================================
         PRODUCT
         ==================================================================== */

      const product = {
        name: productName,
        category: productCategory,
        brand: brand,
        quantity: quantity,
        expiryDate: expiryDate,
        daysRemaining: daysRemaining,
        statusCategory: statusCategory,
      };

      /* ====================================================================
         PROMPT
         ==================================================================== */

      const prompt = `
${DONATION_SUITABILITY_PROMPT}

EXPIRY STATUS:

${expiryStatus}

PRODUCT INFORMATION:

Product name:
${product.name}

Product category:
${product.category}

Brand:
${product.brand || "Unknown"}

Quantity:
${product.quantity || "Unknown"}

Expiry date:
${product.expiryDate}

Days remaining:
${product.daysRemaining}

SmartShelf status:
${product.statusCategory || "Not provided"}

Return ONLY the JSON object required by the schema.
`;

      /* ====================================================================
         LOG REQUEST
         ==================================================================== */

      console.log("");
      console.log(
        "=========================================================="
      );
      console.log(
        "           DONATION GEMINI DEBUG START"
      );
      console.log(
        "=========================================================="
      );

      console.log(
        "User:",
        decodedToken.uid
      );

      console.log(
        "Product:",
        productName
      );

      console.log(
        "Category:",
        productCategory
      );

      console.log(
        "Brand:",
        brand
      );

      console.log(
        "Quantity:",
        quantity
      );

      console.log(
        "Expiry:",
        expiryDate
      );

      console.log(
        "Days remaining:",
        daysRemaining
      );

      console.log(
        "Status:",
        statusCategory
      );

      console.log(
        "Gemini model:",
        GEMINI_DONATION_MODEL
      );

      console.log(
        "=========================================================="
      );

      /* ====================================================================
         GEMINI URL
         ==================================================================== */

      const geminiUrl =
        `https://generativelanguage.googleapis.com/v1beta/models/` +
        `${GEMINI_DONATION_MODEL}:generateContent`;

      console.log(
        "Gemini URL:",
        geminiUrl
      );

      /* ====================================================================
         REQUEST BODY
         ==================================================================== */

      const donationRequestBody = {
        contents: [
          {
            role: "user",

            parts: [
              {
                text: prompt,
              },
            ],
          },
        ],

        generationConfig: {
  responseMimeType: "application/json",
  responseSchema: DONATION_RESPONSE_SCHEMA,
  temperature: 0.1,
  maxOutputTokens: 1024,
  thinkingConfig: {
    thinkingBudget: 0,
  },
},
      };

      console.log("");
      console.log(
        "========== GEMINI REQUEST CONFIG =========="
      );

      console.log(
        JSON.stringify(
          donationRequestBody,
          null,
          2
        )
      );

      console.log(
        "============================================"
      );

      /* ====================================================================
         CALL GEMINI
         ==================================================================== */

      console.log("");
      console.log(
        "========== CALLING GEMINI NOW =========="
      );

      const geminiResponse =
        await fetch(
          geminiUrl,
          {
            method: "POST",

            headers: {
              "Content-Type":
                "application/json",

              "x-goog-api-key":
                GEMINI_API_KEY.value(),
            },

            body:
              JSON.stringify(
                donationRequestBody
              ),
          }
        );

      console.log(
        "========== GEMINI RESPONSE RECEIVED =========="
      );

      console.log(
        "HTTP status:",
        geminiResponse.status
      );

      console.log(
        "HTTP ok:",
        geminiResponse.ok
      );

      console.log(
        "==============================================="
      );

      /* ====================================================================
         READ RAW GEMINI RESPONSE
         ==================================================================== */

      const responseText =
        await geminiResponse.text();

      console.log("");
      console.log(
        "##########################################################"
      );

      console.log(
        "          RAW GEMINI HTTP RESPONSE"
      );

      console.log(
        "##########################################################"
      );

      console.log(
        responseText
      );

      console.log(
        "##########################################################"
      );

      /* ====================================================================
         GEMINI HTTP ERROR
         ==================================================================== */

      if (!geminiResponse.ok) {
        console.error("");
        console.error(
          "!!!!!!!! GEMINI HTTP ERROR !!!!!!!!"
        );

        console.error(
          "Status:",
          geminiResponse.status
        );

        console.error(
          "Response:",
          responseText
        );

        console.error(
          "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        );

        const fallback =
          fallbackDonationResult(
            product
          );

        return res.status(200).json({
          success: true,

          result: fallback,

          usedAi: false,

          fallbackReason:
            `Gemini HTTP error ${geminiResponse.status}`,

          /* DEBUG INFORMATION */
          geminiHttpStatus:
            geminiResponse.status,

          geminiRawHttpResponse:
            responseText,
        });
      }

      /* ====================================================================
         PARSE GEMINI HTTP RESPONSE
         ==================================================================== */

      let geminiData;

      try {
        geminiData =
          JSON.parse(
            responseText
          );
      } catch (error) {
        console.error("");
        console.error(
          "!!!!!!!! GEMINI HTTP JSON PARSE FAILED !!!!!!!!"
        );

        console.error(
          error
        );

        console.error(
          "Raw response:"
        );

        console.error(
          responseText
        );

        console.error(
          "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        );

        const fallback =
          fallbackDonationResult(
            product
          );

        return res.status(200).json({
          success: true,

          result: fallback,

          usedAi: false,

          fallbackReason:
            "Gemini returned invalid API response.",

          geminiHttpStatus:
            geminiResponse.status,

          geminiRawHttpResponse:
            responseText,
        });
      }

      /* ====================================================================
         PRINT COMPLETE GEMINI RESPONSE
         ==================================================================== */

      console.log("");
      console.log(
        "##########################################################"
      );

      console.log(
        "        COMPLETE PARSED GEMINI RESPONSE"
      );

      console.log(
        "##########################################################"
      );

      console.log(
        JSON.stringify(
          geminiData,
          null,
          2
        )
      );

      console.log(
        "##########################################################"
      );

      /* ====================================================================
         CANDIDATE
         ==================================================================== */

      const candidate =
        geminiData?.candidates?.[0];

      if (!candidate) {
        console.error(
          "Gemini returned NO candidate."
        );

        const fallback =
          fallbackDonationResult(
            product
          );

        return res.status(200).json({
          success: true,

          result: fallback,

          usedAi: false,

          fallbackReason:
            "Gemini returned no candidate.",

          geminiRawHttpResponse:
            responseText,

          geminiParsedResponse:
            geminiData,
        });
      }

      /* ====================================================================
         PRINT CANDIDATE
         ==================================================================== */

      console.log("");
      console.log(
        "##########################################################"
      );

      console.log(
        "              GEMINI CANDIDATE"
      );

      console.log(
        "##########################################################"
      );

      console.log(
        JSON.stringify(
          candidate,
          null,
          2
        )
      );

      console.log(
        "##########################################################"
      );

      /* ====================================================================
         FINISH REASON
         ==================================================================== */

      console.log(
        "Gemini finish reason:",
        candidate.finishReason
      );

      /* ====================================================================
         SAFETY / BLOCK
         ==================================================================== */

      if (
        candidate.finishReason === "SAFETY" ||
        candidate.finishReason === "BLOCKLIST" ||
        candidate.finishReason ===
          "PROHIBITED_CONTENT"
      ) {
        console.error(
          "Gemini blocked the request."
        );

        const fallback =
          fallbackDonationResult(
            product
          );

        return res.status(200).json({
          success: true,

          result: fallback,

          usedAi: false,

          fallbackReason:
            "Gemini blocked the request.",

          geminiRawHttpResponse:
            responseText,

          geminiParsedResponse:
            geminiData,

          geminiCandidate:
            candidate,
        });
      }

      /* ====================================================================
         EXTRACT GENERATED TEXT
         ==================================================================== */

      const parts =
        candidate?.content?.parts ||
        [];

      let generatedText = "";

      for (
        const part of parts
      ) {
        if (
          part &&
          typeof part.text ===
            "string"
        ) {
          generatedText +=
            part.text;
        }
      }

      generatedText =
        generatedText.trim();

      /* ====================================================================
         THIS IS THE MOST IMPORTANT LOG
         ==================================================================== */

      console.log("");
      console.log(
        "##########################################################"
      );

      console.log(
        "          ACTUAL GEMINI GENERATED TEXT"
      );

      console.log(
        "##########################################################"
      );

      console.log(
        generatedText
      );

      console.log(
        "##########################################################"
      );

      /* ====================================================================
         EMPTY RESPONSE
         ==================================================================== */

      if (!generatedText) {
        console.error(
          "Gemini returned EMPTY generated text."
        );

        const fallback =
          fallbackDonationResult(
            product
          );

        return res.status(200).json({
          success: true,

          result: fallback,

          usedAi: false,

          fallbackReason:
            "Gemini returned an empty response.",

          geminiRawHttpResponse:
            responseText,

          geminiParsedResponse:
            geminiData,

          geminiCandidate:
            candidate,

          geminiGeneratedText:
            generatedText,
        });
      }

      /* ====================================================================
         CLEAN GEMINI JSON
         ==================================================================== */

      let cleanedText =
        generatedText;

      cleanedText =
        cleanedText.replace(
          /^```json\s*/i,
          ""
        );

      cleanedText =
        cleanedText.replace(
          /^```\s*/i,
          ""
        );

      cleanedText =
        cleanedText.replace(
          /\s*```$/i,
          ""
        );

      cleanedText =
        cleanedText.trim();

      const firstBrace =
        cleanedText.indexOf("{");

      const lastBrace =
        cleanedText.lastIndexOf("}");

      if (
        firstBrace !== -1 &&
        lastBrace !== -1 &&
        lastBrace > firstBrace
      ) {
        cleanedText =
          cleanedText.substring(
            firstBrace,
            lastBrace + 1
          );
      }

      /* ====================================================================
         LOG CLEANED JSON
         ==================================================================== */

      console.log("");
      console.log(
        "##########################################################"
      );

      console.log(
        "          CLEANED GEMINI JSON"
      );

      console.log(
        "##########################################################"
      );

      console.log(
        cleanedText
      );

      console.log(
        "##########################################################"
      );

      /* ====================================================================
         PARSE GEMINI RESULT
         ==================================================================== */

      let geminiResult;

      try {
        geminiResult =
          JSON.parse(
            cleanedText
          );
      } catch (error) {
        console.error("");
        console.error(
          "!!!!!!!! GEMINI DONATION JSON PARSE FAILED !!!!!!!!"
        );

        console.error(
          error
        );

        console.error(
          "Generated text:"
        );

        console.error(
          generatedText
        );

        console.error(
          "Cleaned text:"
        );

        console.error(
          cleanedText
        );

        console.error(
          "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        );

        const fallback =
          fallbackDonationResult(
            product
          );

        return res.status(200).json({
          success: true,

          result: fallback,

          usedAi: false,

          fallbackReason:
            "Gemini returned invalid donation JSON.",

          /* IMPORTANT DEBUG FIELDS */
          geminiGeneratedText:
            generatedText,

          geminiCleanedText:
            cleanedText,

          geminiRawHttpResponse:
            responseText,

          geminiParsedResponse:
            geminiData,

          geminiCandidate:
            candidate,
        });
      }

      /* ====================================================================
         ACTUAL GEMINI RESULT
         ==================================================================== */

      console.log("");
      console.log(
        "##########################################################"
      );

      console.log(
        "           ACTUAL GEMINI DONATION RESULT"
      );

      console.log(
        "##########################################################"
      );

      console.log(
        JSON.stringify(
          geminiResult,
          null,
          2
        )
      );

      console.log(
        "##########################################################"
      );

      /* ====================================================================
         NORMALIZE GEMINI RESULT
         ==================================================================== */

      const normalizedGeminiResult =
        normalizeDonationResult(
          geminiResult
        );

      console.log("");
      console.log(
        "##########################################################"
      );

      console.log(
        "       NORMALIZED GEMINI DONATION RESULT"
      );

      console.log(
        "##########################################################"
      );

      console.log(
        JSON.stringify(
          normalizedGeminiResult,
          null,
          2
        )
      );

      console.log(
        "##########################################################"
      );

      /* ====================================================================
         FINAL RESPONSE
         ==================================================================== */

      console.log("");
      console.log(
        "=========================================================="
      );

      console.log(
        "          GEMINI DONATION SUCCESS"
      );

      console.log(
        "usedAi: TRUE"
      );

      console.log(
        "=========================================================="
      );

      return res.status(200).json({
        success: true,

        /* This is what your Flutter app should use */
        result:
          normalizedGeminiResult,

        /* IMPORTANT */
        usedAi: true,

        model:
          GEMINI_DONATION_MODEL,

        /* DEBUG COMPARISON DATA */
        geminiOriginalResult:
          geminiResult,

        geminiNormalizedResult:
          normalizedGeminiResult,

        geminiGeneratedText:
          generatedText,
      });
    } catch (error) {
      /* ====================================================================
         UNEXPECTED ERROR
         ==================================================================== */

      console.error("");
      console.error(
        "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      );

      console.error(
        "DONATION CLOUD FUNCTION UNEXPECTED ERROR"
      );

      console.error(
        error
      );

      console.error(
        "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      );

      /* ====================================================================
         FALLBACK
         ==================================================================== */

      try {
        const body =
          req.body || {};

        const fallbackProduct = {
          name:
            typeof body.productName ===
            "string"
              ? body.productName.trim()
              : "",

          category:
            typeof body.productCategory ===
            "string"
              ? body.productCategory.trim()
              : "",

          daysRemaining:
            Number(
              body.daysRemaining
            ),
        };

        if (
          fallbackProduct.name &&
          fallbackProduct.category &&
          Number.isFinite(
            fallbackProduct.daysRemaining
          )
        ) {
          const fallback =
            fallbackDonationResult(
              fallbackProduct
            );

          return res.status(200).json({
            success: true,

            result: fallback,

            usedAi: false,

            fallbackReason:
              "Unexpected Cloud Function error.",

            errorDetails:
              error?.message || "",
          });
        }
      } catch (fallbackError) {
        console.error(
          "Donation fallback also failed:",
          fallbackError
        );
      }

      return res.status(500).json({
        success: false,

        error:
          error?.message ||
          "Donation suitability check failed.",
      });
    }
  }
);
/* ==========================================================================
   DONATION PLACE HELPERS
   ========================================================================== */

/* --------------------------------------------------------------------------
   Allowed donation organization types
   -------------------------------------------------------------------------- */

const HUMAN_DONATION_TYPES = [
  "Food Bank",
  "Community Kitchen",
  "NGO",
];

const ANIMAL_DONATION_TYPES = [
  "Gaushala",
  "Animal Shelter",
  "Poultry Farm",
  "Dairy Farm",
  "Cattle Shelter",
  "Animal Husbandry",
  "NGO",
];


/* --------------------------------------------------------------------------
   Check whether Gemini organization type is allowed
   -------------------------------------------------------------------------- */

function isAllowedDonationOrgType(type) {
  if (typeof type !== "string") {
    return false;
  }

  const value =
    type
      .trim()
      .toLowerCase();

  const allowedTypes = [
    "gaushala",
    "animal shelter",
    "poultry farm",
    "dairy farm",
    "cattle shelter",
    "food bank",
    "community kitchen",
    "ngo",
    "animal husbandry",
  ];

  return allowedTypes.some(
    (allowed) =>
      value === allowed ||
      value.includes(allowed)
  );
}


/* --------------------------------------------------------------------------
   Normalize Gemini donation result
   -------------------------------------------------------------------------- */

function normalizeFindDonationResult(result) {
  const raw =
    result &&
    typeof result === "object"
      ? result
      : {};

  const isSuitable =
    raw.isSuitable === true ||
    raw.consumable === true;


  let donationCategory =
    typeof raw.donationCategory === "string"
      ? raw.donationCategory
          .trim()
          .toLowerCase()
      : "";


  switch (donationCategory) {

    case "animal feed":
    case "animal-feed":
      donationCategory =
        "animal_feed";
      break;

    case "human consumption":
    case "human-consumption":
    case "community donation":
      donationCategory =
        "human_consumption";
      break;

    case "non food use":
    case "non-food-use":
    case "non-food":
      donationCategory =
        "non_food_use";
      break;

    case "not suitable":
    case "not_suitable":
      donationCategory =
        "unsafe";
      break;

    case "unsafe":
      donationCategory =
        "unsafe";
      break;

    case "animal_feed":
    case "human_consumption":
    case "non_food_use":
      break;

    default:
      donationCategory =
        "";
  }


  /* ------------------------------------------------------------------------
     Infer category from decision if Gemini didn't provide one
     ------------------------------------------------------------------------ */

  if (!donationCategory) {

    const decision =
      typeof raw.decision === "string"
        ? raw.decision
            .trim()
            .toLowerCase()
        : "";


    if (
      decision.includes("animal") ||
      decision.includes("feed") ||
      decision.includes("cattle") ||
      decision.includes("poultry") ||
      decision.includes("livestock") ||
      decision.includes("gaushala")
    ) {

      donationCategory =
        "animal_feed";

    } else if (
      decision.includes("human") ||
      decision.includes("community") ||
      decision.includes("food bank")
    ) {

      donationCategory =
        "human_consumption";

    } else if (
      decision.includes("non-food") ||
      decision.includes("non food") ||
      decision.includes("recycling")
    ) {

      donationCategory =
        "non_food_use";

    } else if (
      decision.includes("unsafe") ||
      decision.includes("not suitable") ||
      decision.includes("reject")
    ) {

      donationCategory =
        "unsafe";
    }
  }


  /* ------------------------------------------------------------------------
     If Gemini says unsuitable, force unsafe
     ------------------------------------------------------------------------ */

  if (!isSuitable) {
    donationCategory =
      "unsafe";
  }


  if (!donationCategory) {
    donationCategory =
      isSuitable
        ? "unknown"
        : "unsafe";
  }


  /* ------------------------------------------------------------------------
     Reason
     ------------------------------------------------------------------------ */

  const reason =
    typeof raw.reason === "string"
      ? raw.reason.trim()
      : "Donation suitability could not be determined.";


  /* ------------------------------------------------------------------------
     Suggested animals
     ------------------------------------------------------------------------ */

  const suggestedAnimals =
    Array.isArray(
      raw.suggestedAnimals
    )
      ? raw.suggestedAnimals
          .map(
            (item) =>
              String(item).trim()
          )
          .filter(
            (item) =>
              item.length > 0
          )
      : [];


  /* ------------------------------------------------------------------------
     Suggested organization types
     ------------------------------------------------------------------------ */

  const suggestedOrgTypes =
    Array.isArray(
      raw.suggestedOrgTypes
    )
      ? raw.suggestedOrgTypes
          .map(
            (item) =>
              String(item).trim()
          )
          .filter(
            (item) =>
              item.length > 0
          )
      : [];


  return {
    isSuitable,
    donationCategory,
    reason:
      reason ||
      "Donation suitability could not be determined.",
    suggestedAnimals,
    suggestedOrgTypes,
  };
}


/* --------------------------------------------------------------------------
   Normalize user location
   -------------------------------------------------------------------------- */

function normalizeDonationLocation(value) {

  if (
    typeof value !== "string"
  ) {
    return "";
  }

  return value
    .trim()
    .replace(
      /\s+/g,
      " "
    );
}


/* --------------------------------------------------------------------------
   Build SerpAPI donation query
   -------------------------------------------------------------------------- */

function buildDonationSearchQuery(
  organizationType,
  location,
  suggestedAnimals
) {

  if (
    organizationType ===
      "Food Bank" ||
    organizationType ===
      "Community Kitchen"
  ) {

    return `${organizationType} food donation ${location}`;
  }


  if (
    organizationType ===
      "NGO"
  ) {

    if (
      suggestedAnimals.length >
      0
    ) {

      return `NGO ${suggestedAnimals.join(
        " "
      )} donation ${location}`;
    }

    return `NGO food donation ${location}`;
  }


  if (
    suggestedAnimals.length >
    0
  ) {

    return `${organizationType} ${suggestedAnimals.join(
      " "
    )} animal feed donation ${location}`;
  }


  return `${organizationType} animal feed donation ${location}`;
}


/* --------------------------------------------------------------------------
   Check whether SerpAPI result is relevant
   -------------------------------------------------------------------------- */

function isRelevantDonationSearchResult(
  result,
  organizationType
) {

  if (
    !result ||
    typeof result !== "object"
  ) {
    return false;
  }


  const title =
    String(
      result.title ||
      ""
    )
      .toLowerCase();


  const type =
    String(
      result.type ||
      ""
    )
      .toLowerCase();


  const description =
    String(
      result.description ||
      ""
    )
      .toLowerCase();


  const combined =
    `${title} ${type} ${description}`;


  const keywords =
    organizationType
      .toLowerCase()
      .split(/\s+/)
      .filter(
        (word) =>
          word.length > 2
      );


  /*
   * Google Maps results can have slightly
   * different category names, so we use
   * partial matching instead of exact matching.
   */

  if (
    organizationType ===
      "Food Bank"
  ) {

    return (
      combined.includes("food bank") ||
      combined.includes("foodbank") ||
      combined.includes("food donation")
    );
  }


  if (
    organizationType ===
      "Community Kitchen"
  ) {

    return (
      combined.includes("community kitchen") ||
      combined.includes("kitchen") ||
      combined.includes("food")
    );
  }


  if (
    organizationType ===
      "Gaushala"
  ) {

    return (
      combined.includes("gaushala") ||
      combined.includes("cow shelter") ||
      combined.includes("cattle")
    );
  }


  if (
    organizationType ===
      "Animal Shelter"
  ) {

    return (
      combined.includes("animal shelter") ||
      combined.includes("animal rescue") ||
      combined.includes("pet shelter")
    );
  }


  if (
    organizationType ===
      "Poultry Farm"
  ) {

    return (
      combined.includes("poultry") ||
      combined.includes("chicken farm")
    );
  }


  if (
    organizationType ===
      "Dairy Farm"
  ) {

    return (
      combined.includes("dairy") ||
      combined.includes("milk farm") ||
      combined.includes("cattle")
    );
  }


  if (
    organizationType ===
      "Cattle Shelter"
  ) {

    return (
      combined.includes("cattle") ||
      combined.includes("cow shelter") ||
      combined.includes("gaushala")
    );
  }


  if (
    organizationType ===
      "Animal Husbandry"
  ) {

    return (
      combined.includes("animal husbandry") ||
      combined.includes("livestock") ||
      combined.includes("cattle") ||
      combined.includes("poultry")
    );
  }


  if (
    organizationType ===
      "NGO"
  ) {

    return (
      combined.includes("ngo") ||
      combined.includes("non profit") ||
      combined.includes("non-profit") ||
      combined.includes("charity")
    );
  }


  return keywords.some(
    (keyword) =>
      combined.includes(
        keyword
      )
  );
}


/* --------------------------------------------------------------------------
   Normalize SerpAPI place
   -------------------------------------------------------------------------- */

function normalizeDonationSearchPlace(
  result,
  organizationType,
  location,
  index
) {

  const name =
    String(
      result.title ||
      ""
    ).trim();


  const address =
    String(
      result.address ||
      ""
    ).trim();


  const phone =
    result.phone
      ? String(
          result.phone
        ).trim()
      : null;


  const rating =
    typeof result.rating ===
    "number"
      ? result.rating
      : Number.isFinite(
          Number(
            result.rating
          )
        )
        ? Number(
            result.rating
          )
        : null;


  const reviewCount =
    Number.isFinite(
      Number(
        result.reviews
      )
    )
      ? Number(
          result.reviews
        )
      : null;


  const latitude =
    Number.isFinite(
      Number(
        result.gps_coordinates
          ?.latitude
      )
    )
      ? Number(
          result.gps_coordinates
            .latitude
        )
      : null;


  const longitude =
    Number.isFinite(
      Number(
        result.gps_coordinates
          ?.longitude
      )
    )
      ? Number(
          result.gps_coordinates
            .longitude
        )
      : null;


  const placeId =
    result.place_id ||
    result.data_id ||
    result.data_cid ||
    null;


  let googleMapsUrl =
    result.links?.directions ||
    result.link ||
    null;


  if (
    !googleMapsUrl &&
    latitude !== null &&
    longitude !== null
  ) {

    googleMapsUrl =
      "https://www.google.com/maps/search/?api=1" +
      `&query=${latitude},${longitude}`;
  }


  if (
    !googleMapsUrl &&
    name
  ) {

    const query =
      encodeURIComponent(
        `${name}, ${address}`
      );

    googleMapsUrl =
      "https://www.google.com/maps/search/?api=1" +
      `&query=${query}`;
  }


  return {

    id:
      placeId ||
      `${organizationType}-${index}`,

    name,

    type:
      organizationType,

    address,

    phone,

    rating,

    reviewCount,

    latitude,

    longitude,

    distanceKm:
      null,

    placeId,

    mapsUrl:
      googleMapsUrl,

    googleMapsUrl,

    description:
      result.description
        ? String(
            result.description
          ).trim()
        : "",

    thumbnail:
      result.thumbnail ||
      null,

    location,

    source:
      "SerpAPI Google Maps",
  };
}


/* --------------------------------------------------------------------------
   Deduplicate donation places
   -------------------------------------------------------------------------- */

function deduplicateDonationPlaces(
  places
) {

  const seen =
    new Set();

  const result =
    [];


  for (
    const place of places
  ) {

    const key =
      String(
        place.placeId ||
        place.id ||
        `${place.name}|${place.address}`
      )
        .trim()
        .toLowerCase();


    if (
      !key ||
      seen.has(key)
    ) {
      continue;
    }


    seen.add(key);

    result.push(
      place
    );
  }


  return result;
}


/* ==========================================================================
   FIND DONATION PLACES CLOUD FUNCTION
   ========================================================================== */

exports.findDonationPlaces =
  onRequest(
    {
      region: "asia-south2",

      /*
       * Gemini is used to determine donation suitability.
       * SerpAPI is used only after Gemini approves donation.
       */
      secrets: [
        GEMINI_API_KEY,
        SERP_API_KEY,
      ],

      cors: true,

      timeoutSeconds: 60,

      memory: "256MiB",

      maxInstances: 3,
    },

    async (
      req,
      res
    ) => {

      /* ----------------------------------------------------------------------
         CORS
         ---------------------------------------------------------------------- */

      res.set(
        "Access-Control-Allow-Origin",
        "*"
      );

      res.set(
        "Access-Control-Allow-Headers",
        "Content-Type, Authorization"
      );

      res.set(
        "Access-Control-Allow-Methods",
        "POST, OPTIONS"
      );


      if (
        req.method ===
        "OPTIONS"
      ) {

        return res
          .status(204)
          .send("");
      }


      /* ----------------------------------------------------------------------
         METHOD
         ---------------------------------------------------------------------- */

      if (
        req.method !==
        "POST"
      ) {

        return res
          .status(405)
          .json({
            success: false,

            error:
              "Method not allowed. Use POST.",
          });
      }


      /* ----------------------------------------------------------------------
         AUTHENTICATION
         ---------------------------------------------------------------------- */

      let decodedToken;

      try {

        decodedToken =
          await verifyFirebaseUser(
            req
          );

      } catch (
        error
      ) {

        return res
          .status(
            error.statusCode ||
              401
          )
          .json({

            success: false,

            error:
              error.message ||
              "Authentication failed.",
          });
      }


      try {

        /* ====================================================================
           PRODUCT DATA
           ==================================================================== */

        const body =
          req.body ||
          {};


        const productName =
          typeof body.productName ===
          "string"
            ? body.productName.trim()
            : "";


        const productCategory =
          typeof body.productCategory ===
          "string"
            ? body.productCategory.trim()
            : "";


        const statusCategory =
          typeof body.statusCategory ===
          "string"
            ? body.statusCategory.trim()
            : "";


        const brand =
          typeof body.brand ===
          "string"
            ? body.brand.trim()
            : "";


        const quantity =
          body.quantity;


        const expiryDate =
          typeof body.expiryDate ===
          "string"
            ? body.expiryDate.trim()
            : "";


        const daysRemaining =
          Number(
            body.daysRemaining
          );


        /* ====================================================================
           VALIDATION
           ==================================================================== */

        if (
          !productName ||
          !productCategory ||
          !statusCategory ||
          !expiryDate ||
          !Number.isFinite(
            daysRemaining
          )
        ) {

          return res
            .status(400)
            .json({

              success: false,

              error:
                "Missing or invalid product information.",
            });
        }


        /* ====================================================================
           LOG REQUEST
           ==================================================================== */

        console.log(
          "=================================================="
        );

        console.log(
          "FIND DONATION PLACES"
        );

        console.log(
          "User:",
          decodedToken.uid
        );

        console.log(
          "Product:",
          productName
        );

        console.log(
          "Category:",
          productCategory
        );

        console.log(
          "Status:",
          statusCategory
        );

        console.log(
          "Brand:",
          brand
        );

        console.log(
          "Quantity:",
          quantity
        );

        console.log(
          "Expiry date:",
          expiryDate
        );

        console.log(
          "Days remaining:",
          daysRemaining
        );

        console.log(
          "=================================================="
        );


        /* ====================================================================
           GET SAVED USER LOCATION
           ==================================================================== */

        const userDoc =
          await db
            .collection(
              "users"
            )
            .doc(
              decodedToken.uid
            )
            .get();


        if (
          !userDoc.exists
        ) {

          return res
            .status(404)
            .json({

              success: false,

              error:
                "User profile not found.",
            });
        }


        const userData =
          userDoc.data() ||
          {};


        const location =
          normalizeDonationLocation(
            userData.location
          );


        if (!location) {

          return res
            .status(400)
            .json({

              success: false,

              error:
                "No location is saved for this user. Please add your location first.",
            });
        }


        console.log(
          "User saved location:",
          location
        );


        /* ====================================================================
           GEMINI DONATION ANALYSIS
           ==================================================================== */

        const geminiRequestBody = {

          contents: [
            {
              role: "user",

              parts: [
                {
                  text:
                    DONATION_SUITABILITY_PROMPT +
                    "\n\nPRODUCT DATA:\n" +
                    JSON.stringify(
                      {
                        productName,
                        productCategory,
                        statusCategory,
                        brand,
                        quantity,
                        expiryDate,
                        daysRemaining,
                      },
                      null,
                      2
                    ),
                },
              ],
            },
          ],

          generationConfig: {

            responseMimeType:
              "application/json",

            responseSchema:
              DONATION_RESPONSE_SCHEMA,

            temperature:
              0.1,
          },
        };


        const geminiUrl =
          `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_DONATION_MODEL}:generateContent`;


        console.log(
          "Calling Gemini for donation suitability..."
        );

        console.log(
          "Gemini model:",
          GEMINI_DONATION_MODEL
        );


        const geminiResponse =
          await fetch(
            geminiUrl,
            {

              method:
                "POST",

              headers: {

                "Content-Type":
                  "application/json",

                "x-goog-api-key":
                  GEMINI_API_KEY.value(),
              },

              body:
                JSON.stringify(
                  geminiRequestBody
                ),
            }
          );


        const geminiResponseText =
          await geminiResponse.text();


        console.log(
          "Gemini HTTP status:",
          geminiResponse.status
        );


        console.log(
          "Gemini raw response:",
          geminiResponseText
        );


        /* ====================================================================
           GEMINI HTTP ERROR
           ==================================================================== */

        if (
          !geminiResponse.ok
        ) {

          return res
            .status(502)
            .json({

              success: false,

              error:
                "Gemini donation analysis failed.",

              geminiStatus:
                geminiResponse.status,

              geminiResponse:
                geminiResponseText,
            });
        }


        /* ====================================================================
           PARSE GEMINI HTTP RESPONSE
           ==================================================================== */

        let geminiData;

        try {

          geminiData =
            JSON.parse(
              geminiResponseText
            );

        } catch (
          error
        ) {

          console.error(
            "Gemini response JSON parse error:",
            error
          );

          return res
            .status(502)
            .json({

              success: false,

              error:
                "Gemini returned an invalid response.",

              geminiResponse:
                geminiResponseText,
            });
        }


        /* ====================================================================
           GET CANDIDATE
           ==================================================================== */

        const candidate =
          geminiData
            ?.candidates?.[0];


        if (
          !candidate
        ) {

          return res
            .status(502)
            .json({

              success: false,

              error:
                "Gemini returned no donation analysis.",

              geminiResponse:
                geminiData,
            });
        }


        console.log(
          "Gemini finish reason:",
          candidate.finishReason
        );


        /* ====================================================================
           SAFETY BLOCK
           ==================================================================== */

        if (
          candidate.finishReason ===
            "SAFETY" ||

          candidate.finishReason ===
            "BLOCKLIST" ||

          candidate.finishReason ===
            "PROHIBITED_CONTENT"
        ) {

          return res
            .status(200)
            .json({

              success: true,

              location,

              donation: {

                isSuitable:
                  false,

                donationCategory:
                  "unsafe",

                reason:
                  "Gemini could not safely evaluate this product for donation.",

                suggestedAnimals:
                  [],

                suggestedOrgTypes:
                  [],
              },

              places: [],

              usedAi:
                true,

              usedSearchApi:
                false,
            });
        }


        /* ====================================================================
           EXTRACT GEMINI TEXT
           ==================================================================== */

        const parts =
          candidate
            ?.content
            ?.parts ||
          [];


        let generatedText =
          "";


        for (
          const part of parts
        ) {

          if (
            part &&
            typeof part.text ===
              "string"
          ) {

            generatedText +=
              part.text;
          }
        }


        generatedText =
          generatedText.trim();


        console.log(
          "=================================================="
        );

        console.log(
          "ACTUAL GEMINI GENERATED TEXT"
        );

        console.log(
          generatedText
        );

        console.log(
          "=================================================="
        );


        if (
          !generatedText
        ) {

          return res
            .status(502)
            .json({

              success: false,

              error:
                "Gemini returned an empty donation analysis.",

              usedAi:
                true,

              usedSearchApi:
                false,
            });
        }


        /* ====================================================================
           CLEAN JSON MARKDOWN
           ==================================================================== */

        let cleanedText =
          generatedText;


        cleanedText =
          cleanedText.replace(
            /^```json\s*/i,
            ""
          );


        cleanedText =
          cleanedText.replace(
            /^```\s*/i,
            ""
          );


        cleanedText =
          cleanedText.replace(
            /\s*```$/i,
            ""
          );


        cleanedText =
          cleanedText.trim();


        const firstBrace =
          cleanedText.indexOf(
            "{"
          );


        const lastBrace =
          cleanedText.lastIndexOf(
            "}"
          );


        if (
          firstBrace !== -1 &&
          lastBrace !== -1 &&
          lastBrace >
            firstBrace
        ) {

          cleanedText =
            cleanedText.substring(
              firstBrace,
              lastBrace + 1
            );
        }


        /* ====================================================================
           PARSE GEMINI DONATION JSON
           ==================================================================== */

        let geminiResult;

        try {

          geminiResult =
            JSON.parse(
              cleanedText
            );

        } catch (
          error
        ) {

          console.error(
            "Gemini donation JSON parse failed:",
            error
          );

          return res
            .status(502)
            .json({

              success: false,

              error:
                "Gemini returned invalid donation JSON.",

              geminiGeneratedText:
                generatedText,
            });
        }


        /* ====================================================================
           NORMALIZE RESULT
           ==================================================================== */

        const donation =
          normalizeFindDonationResult(
            geminiResult
          );


        console.log(
          "=================================================="
        );

        console.log(
          "NORMALIZED GEMINI DONATION RESULT"
        );

        console.log(
          JSON.stringify(
            donation,
            null,
            2
          )
        );

        console.log(
          "=================================================="
        );


        /* ====================================================================
           IMPORTANT:
           ALWAYS RETURN GEMINI RESULT.

           This fixes:
           "Donation analysis returned no result."
           ==================================================================== */

        if (
          !donation.isSuitable
        ) {

          console.log(
            "Gemini says product is NOT suitable for donation."
          );

          return res
            .status(200)
            .json({

              success:
                true,

              location,

              donation,

              places: [],

              usedAi:
                true,

              usedSearchApi:
                false,

              geminiGeneratedText:
                generatedText,
            });
        }


        /* ====================================================================
           GET DONATION DATA
           ==================================================================== */

        const donationCategory =
          donation.donationCategory;


        const suggestedAnimals =
          donation.suggestedAnimals;


        const suggestedOrgTypes =
          donation.suggestedOrgTypes;


        /* ====================================================================
           SAFETY CHECK
           ==================================================================== */

        if (
          donationCategory ===
            "unsafe" ||

          donationCategory ===
            "unknown"
        ) {

          return res
            .status(200)
            .json({

              success:
                true,

              location,

              donation,

              places: [],

              usedAi:
                true,

              usedSearchApi:
                false,

              geminiGeneratedText:
                generatedText,
            });
        }


        /* ====================================================================
           FILTER ORGANIZATION TYPES
           ==================================================================== */

        let allowedOrgTypes =
          suggestedOrgTypes.filter(
            isAllowedDonationOrgType
          );


        allowedOrgTypes =
          [
            ...new Set(
              allowedOrgTypes
            ),
          ];


        /* --------------------------------------------------------------------
           HUMAN CONSUMPTION
           -------------------------------------------------------------------- */

        if (
          donationCategory ===
          "human_consumption"
        ) {

          allowedOrgTypes =
            allowedOrgTypes.filter(
              (type) =>
                HUMAN_DONATION_TYPES.includes(
                  type
                )
            );
        }


        /* --------------------------------------------------------------------
           ANIMAL FEED
           -------------------------------------------------------------------- */

        if (
          donationCategory ===
          "animal_feed"
        ) {

          allowedOrgTypes =
            allowedOrgTypes.filter(
              (type) =>
                ANIMAL_DONATION_TYPES.includes(
                  type
                )
            );
        }


        console.log(
          "Final organization types:",
          allowedOrgTypes
        );


        /* ====================================================================
           NO COMPATIBLE ORGANIZATION TYPE
           ==================================================================== */

        if (
          allowedOrgTypes.length ===
          0
        ) {

          return res
            .status(200)
            .json({

              success:
                true,

              location,

              donation,

              places: [],

              usedAi:
                true,

              usedSearchApi:
                false,

              message:
                "Gemini found the product potentially suitable, but did not provide compatible donation organization types.",

              geminiGeneratedText:
                generatedText,
            });
        }


        /* ====================================================================
           SERPAPI SEARCH
           ==================================================================== */

        const searchTasks =
          allowedOrgTypes.map(
            async (
              organizationType
            ) => {

              const query =
                buildDonationSearchQuery(
                  organizationType,
                  location,
                  suggestedAnimals
                );


              console.log(
                "=================================================="
              );

              console.log(
                "SERPAPI DONATION SEARCH"
              );

              console.log(
                "Organization type:",
                organizationType
              );

              console.log(
                "Query:",
                query
              );

              console.log(
                "=================================================="
              );


              try {

                const params =
                  new URLSearchParams({

                    engine:
                      "google_maps",

                    type:
                      "search",

                    q:
                      query,

                    google_domain:
                      "google.com",

                    gl:
                      "in",

                    hl:
                      "en",

                    device:
                      "desktop",

                    start:
                      "0",

                    api_key:
                      SERP_API_KEY.value(),
                  });


                const serpUrl =
                  `https://serpapi.com/search.json?${params.toString()}`;


                const serpResponse =
                  await fetch(
                    serpUrl
                  );


                const serpText =
                  await serpResponse.text();


                console.log(
                  "SerpAPI HTTP status:",
                  serpResponse.status
                );


                if (
                  !serpResponse.ok
                ) {

                  console.error(
                    "SerpAPI error:",
                    serpText
                  );

                  return [];
                }


                const data =
                  JSON.parse(
                    serpText
                  );


                const localResults =
                  Array.isArray(
                    data.local_results
                  )
                    ? data.local_results
                    : [];


                console.log(
                  `Found ${localResults.length} raw results for ${organizationType}`
                );


                const relevantResults =
                  localResults.filter(
                    (result) =>
                      isRelevantDonationSearchResult(
                        result,
                        organizationType
                      )
                  );


                console.log(
                  `Found ${relevantResults.length} relevant results for ${organizationType}`
                );


                return relevantResults
                  .slice(
                    0,
                    10
                  )
                  .map(
                    (
                      result,
                      index
                    ) =>
                      normalizeDonationSearchPlace(
                        result,
                        organizationType,
                        location,
                        index
                      )
                  );


              } catch (
                error
              ) {

                console.error(
                  `Donation place search failed for ${organizationType}:`,
                  error
                );

                return [];
              }
            }
          );


        const searchResults =
          await Promise.all(
            searchTasks
          );


        let places =
          searchResults.flat();


        /* ====================================================================
           DEDUPLICATE
           ==================================================================== */

        places =
          deduplicateDonationPlaces(
            places
          );


        /* ====================================================================
           LIMIT RESULTS
           ==================================================================== */

        places =
          places.slice(
            0,
            20
          );


        /* ====================================================================
           FINAL RESPONSE
           ==================================================================== */

        console.log(
          "=================================================="
        );

        console.log(
          "FINAL DONATION RESPONSE"
        );

        console.log(
          "Location:",
          location
        );

        console.log(
          "Donation category:",
          donationCategory
        );

        console.log(
          "Places found:",
          places.length
        );

        console.log(
          "=================================================="
        );


        return res
          .status(200)
          .json({

            success:
              true,

            location,

            donation,

            places,

            usedAi:
              true,

            usedSearchApi:
              true,

            geminiGeneratedText:
              generatedText,
          });


      } catch (
        error
      ) {

        console.error(
          "Find donation places error:",
          error
        );


        return res
          .status(500)
          .json({

            success:
              false,

            error:
              error?.message ||
              "Something went wrong while finding donation places.",
          });
      }
    }
  );