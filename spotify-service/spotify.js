const express = require('express');
const cors = require('cors');
const SpotifyWebApi = require('spotify-web-api-node');

const app = express();

app.use(cors());



// Function to search for tracks based on a flexible query
async function searchSpotify(query) {
  try {
    const clientId = 'CLIENT_ID';
    const clientSecret = 'CLIENT_SECRET';

    const spotifyApi = new SpotifyWebApi({
      clientId: clientId,
      clientSecret: clientSecret
    });

    const data = await spotifyApi.clientCredentialsGrant();
    spotifyApi.setAccessToken(data.body['access_token']);
    // Search for tracks using the flexible query
    const searchResults = await spotifyApi.searchTracks(query, { limit: 1 });

    if (searchResults.body.tracks.items.length > 0) {
      const results = searchResults.body.tracks.items.map(item => {
        const cleanedTrackName = item.name.replace(/ *\([^)]*\) */g, '').replace(/ *\[[^\]]*]/g, '');

        return {
          track: {
            name: cleanedTrackName,
            preview_url: item.preview_url,
            external_urls: item.external_urls.spotify
          },
          album: {
            name: item.album.name,
            release_date: item.album.release_date,
            external_urls: item.album.external_urls.spotify
          },
          artists: item.artists.map(artist => ({
            name: artist.name,
            external_urls: artist.external_urls.spotify
          })),
          images: item.album.images.map(image => ({
            url: image.url,
            width: image.width,
            height: image.height
          }))
        };
      });

      return results;
    } else {
      return null;
    }
  } catch (error) {
    console.error('Error searching Spotify:', error);
    return null;
  }
}


// Define a route that returns JSON based on a flexible query
// Define a route that returns the items array based on a flexible query
app.get('/search', (req, res) => {
  const query = req.query.q;

  if (!query) {
    return res.status(400).json({ error: 'Please provide a query parameter (q)' });
  }

  searchSpotify(query)
    .then(result => {
      if (result && result.length > 0) {
        res.json(result); // Directly return the items array
      } else {
        res.status(404).json({ error: `No results found for query: ${query}` });
      }
    })
    .catch(error => {
      console.error('Error processing request:', error);
      res.status(500).json({ error: 'Internal server error' });
    });
});


const port = parseInt(process.env.PORT) || 8080;
app.listen(port, () => {
  console.log(`helloworld: listening on port ${port}`);
});