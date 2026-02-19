const axios = require('axios');

// API Keys und Endpoints
const BING_API_KEY = process.env.BING_API_KEY;
const YOUTUBE_API_KEY = process.env.YOUTUBE_API_KEY;
const GOOGLE_SEARCH_API_KEY = process.env.GOOGLE_SEARCH_API_KEY;
const GOOGLE_SEARCH_ENGINE_ID = process.env.GOOGLE_SEARCH_ENGINE_ID;

// API Endpoints
const BING_SEARCH_ENDPOINT = 'https://api.bing.microsoft.com/v7.0/search';
const YOUTUBE_SEARCH_ENDPOINT = 'https://www.googleapis.com/youtube/v3/search';
const GOOGLE_CUSTOM_SEARCH_ENDPOINT = 'https://www.googleapis.com/customsearch/v1';
const DUCKDUCKGO_ENDPOINT = 'https://api.duckduckgo.com/';
const WIKIPEDIA_ENDPOINT = 'https://en.wikipedia.org/api/rest_v1/page/summary';

exports.handler = async (event, context) => {
  // CORS Headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Content-Type': 'application/json'
  };

  // Handle preflight requests
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: ''
    };
  }

  if (event.httpMethod !== 'GET') {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' })
    };
  }

  try {
    const { query, type = 'web', count = 10, offset = 0 } = event.queryStringParameters || {};
    
    if (!query) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Query parameter is required' })
      };
    }

    let results = {};

    switch (type) {
      case 'web':
        results = await searchWeb(query, count, offset);
        break;
      case 'images':
        results = await searchImages(query, count);
        break;
      case 'videos':
        results = await searchVideos(query, count);
        break;
      case 'wikipedia':
        results = await searchWikipedia(query);
        break;
      case 'all':
        // Parallele Suche für alle Typen
        const [webResults, imageResults, videoResults, wikipediaInfo] = await Promise.allSettled([
          searchWeb(query, Math.min(count, 8), offset),
          searchImages(query, Math.min(count, 6)),
          searchVideos(query, Math.min(count, 6)),
          searchWikipedia(query)
        ]);

        results = {
          web: webResults.status === 'fulfilled' ? webResults.value : { results: [], totalEstimatedMatches: 0 },
          images: imageResults.status === 'fulfilled' ? imageResults.value : { results: [] },
          videos: videoResults.status === 'fulfilled' ? videoResults.value : { results: [] },
          wikipedia: wikipediaInfo.status === 'fulfilled' ? wikipediaInfo.value : null
        };
        break;
      default:
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Invalid search type. Use: web, images, videos, wikipedia, or all' })
        };
    }

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        query,
        type,
        ...results
      })
    };

  } catch (error) {
    console.error('Search error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      })
    };
  }
};

// Web Search (Bing mit DuckDuckGo Fallback)
async function searchWeb(query, count, offset) {
  // Erlaube bis zu 50 Ergebnisse statt nur 10
  const requestCount = Math.min(count, 50);
  
  try {
    // Versuche zuerst Bing (wenn API Key vorhanden)
    if (BING_API_KEY) {
      console.log(`Searching Bing for: ${query} (count: ${requestCount})`);
      
      const response = await axios.get(BING_SEARCH_ENDPOINT, {
        headers: {
          'Ocp-Apim-Subscription-Key': BING_API_KEY
        },
        params: {
          q: query,
          count: requestCount,
          offset: offset,
          responseFilter: 'Webpages',
          textDecorations: false,
          textFormat: 'Raw'
        }
      });

      const webPages = response.data.webPages?.value || [];
      
      if (webPages.length > 0) {
        return {
          results: webPages.map(page => ({
            title: page.name,
            url: page.url,
            description: page.snippet || '',
            displayUrl: page.displayUrl,
            contentType: 'web',
            source: 'bing'
          })),
          totalEstimatedMatches: response.data.webPages?.totalEstimatedMatches || 0,
          source: 'bing'
        };
      }
    }
  } catch (error) {
    console.error('Bing search failed, trying DuckDuckGo fallback:', error.message);
  }

  // Fallback zu DuckDuckGo (immer kostenlos, keine API Key nötig)
  try {
    console.log(`Fallback: Searching DuckDuckGo for: ${query}`);
    
    const response = await axios.get(DUCKDUCKGO_ENDPOINT, {
      params: {
        q: query,
        format: 'json',
        no_html: '1',
        skip_disambig: '1'
      },
      timeout: 10000
    });

    const results = [];
    
    // DuckDuckGo Instant Answer
    if (response.data.Abstract) {
      results.push({
        title: response.data.Heading || 'DuckDuckGo Instant Answer',
        url: response.data.AbstractURL || `https://duckduckgo.com/?q=${encodeURIComponent(query)}`,
        description: response.data.Abstract,
        displayUrl: 'duckduckgo.com',
        contentType: 'web',
        source: 'duckduckgo-instant'
      });
    }

    // DuckDuckGo Related Topics
    if (response.data.RelatedTopics) {
      const topics = response.data.RelatedTopics
        .filter(topic => topic.FirstURL && topic.Text)
        .slice(0, Math.max(requestCount - results.length, 10))
        .map(topic => ({
          title: topic.Text.split(' - ')[0] || 'Related Topic',
          url: topic.FirstURL,
          description: topic.Text,
          displayUrl: new URL(topic.FirstURL).hostname,
          contentType: 'web',
          source: 'duckduckgo-related'
        }));
      
      results.push(...topics);
    }

    // Falls immer noch nicht genug Ergebnisse, füge Standard-Suchlink hinzu
    if (results.length === 0) {
      results.push({
        title: `Search results for "${query}"`,
        url: `https://duckduckgo.com/?q=${encodeURIComponent(query)}`,
        description: `Search for "${query}" on DuckDuckGo`,
        displayUrl: 'duckduckgo.com',
        contentType: 'web',
        source: 'duckduckgo-fallback'
      });
    }

    return {
      results: results.slice(0, requestCount),
      totalEstimatedMatches: results.length,
      source: 'duckduckgo'
    };

  } catch (duckError) {
    console.error('DuckDuckGo search also failed:', duckError.message);
    
    // Letzter Fallback: Einfacher Suchlink
    return {
      results: [{
        title: `Search for "${query}"`,
        url: `https://duckduckgo.com/?q=${encodeURIComponent(query)}`,
        description: `No search results available. Click to search manually.`,
        displayUrl: 'duckduckgo.com',
        contentType: 'web',
        source: 'fallback'
      }],
      totalEstimatedMatches: 1,
      source: 'fallback'
    };
  }
}

// Image Search (Google Custom Search)
async function searchImages(query, count = 10) {
  if (!GOOGLE_SEARCH_API_KEY || !GOOGLE_SEARCH_ENGINE_ID) {
    throw new Error('Google Custom Search API key or Search Engine ID not configured');
  }

  try {
    const response = await axios.get(GOOGLE_CUSTOM_SEARCH_ENDPOINT, {
      params: {
        key: GOOGLE_SEARCH_API_KEY,
        cx: GOOGLE_SEARCH_ENGINE_ID,
        q: query,
        searchType: 'image',
        num: Math.min(count, 10),
        imgSize: 'medium',
        safe: 'moderate',
        rights: 'cc_publicdomain,cc_attribute,cc_sharealike,cc_noncommercial'
      }
    });

    const images = response.data.items || [];
    
    return {
      results: images.map(image => ({
        title: image.title || 'Untitled Image',
        url: image.link,
        imageUrl: image.link,
        thumbnailUrl: image.image?.thumbnailLink,
        description: image.snippet || '',
        displayUrl: image.displayLink,
        width: image.image?.width,
        height: image.image?.height,
        publisher: image.displayLink,
        contentType: 'image'
      }))
    };
  } catch (error) {
    console.error('Images search error:', error.response?.data || error.message);
    if (error.response?.status === 429) {
      throw new Error('Google Custom Search API quota exceeded (100/day limit)');
    }
    throw error;
  }
}

// Video Search (YouTube Data API)
async function searchVideos(query, count = 10) {
  if (!YOUTUBE_API_KEY) {
    throw new Error('YouTube API key not configured');
  }

  try {
    const response = await axios.get(YOUTUBE_SEARCH_ENDPOINT, {
      params: {
        key: YOUTUBE_API_KEY,
        part: 'snippet',
        q: query,
        type: 'video',
        maxResults: Math.min(count, 50),
        order: 'relevance',
        safeSearch: 'moderate',
        videoDefinition: 'any',
        videoDuration: 'any'
      }
    });

    const videos = response.data.items || [];
    
    return {
      results: videos.map(video => ({
        title: video.snippet.title,
        url: `https://www.youtube.com/watch?v=${video.id.videoId}`,
        videoUrl: `https://www.youtube.com/watch?v=${video.id.videoId}`,
        thumbnailUrl: video.snippet.thumbnails?.medium?.url || video.snippet.thumbnails?.default?.url,
        description: video.snippet.description,
        displayUrl: 'youtube.com',
        publisher: video.snippet.channelTitle,
        publishedAt: video.snippet.publishedAt,
        contentType: 'video'
      }))
    };
  } catch (error) {
    console.error('Videos search error:', error.response?.data || error.message);
    if (error.response?.status === 403) {
      throw new Error('YouTube API quota exceeded or invalid key');
    }
    throw error;
  }
}

// Wikipedia Search
async function searchWikipedia(query) {
  try {
    // First, search for the page
    const searchResponse = await axios.get('https://en.wikipedia.org/api/rest_v1/page/search', {
      params: {
        q: query,
        limit: 1
      }
    });

    const searchResults = searchResponse.data.pages || [];
    if (searchResults.length === 0) {
      return null;
    }

    const pageTitle = searchResults[0].title;
    
    // Get page summary
    const summaryResponse = await axios.get(`${WIKIPEDIA_ENDPOINT}/${encodeURIComponent(pageTitle)}`);
    const data = summaryResponse.data;

    return {
      title: data.title,
      summary: data.extract,
      articleURL: data.content_urls?.desktop?.page || `https://en.wikipedia.org/wiki/${encodeURIComponent(pageTitle)}`,
      imageURL: data.thumbnail?.source,
      coordinates: data.coordinates ? {
        lat: data.coordinates.lat,
        lon: data.coordinates.lon
      } : null
    };
  } catch (error) {
    console.error('Wikipedia search error:', error);
    return null;
  }
}