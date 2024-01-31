const express = require('express');
const geniusApiKey = 'GENIUS_API';

const { getLyrics, getSong } = require('genius-lyrics-api');

const app = express();
const port = process.env.PORT || 8080;

app.get('/lyrics', async (req, res) => {
  try {
    const { title, artist } = req.query;

    if (!title || !artist) {
      return res.status(400).send({ error: 'Title and artist are required in the query parameters.' });
    }

    const options = {
      apiKey: geniusApiKey,
      title,
      artist,
      optimizeQuery: true
    };

    const response = await getSong(options);
    const lines = response.lyrics.split('\n') // Split the lyrics into an array of lines
      .filter(line => !line.startsWith('[') && !line.endsWith(']')); // Filter out lines starting with '[' and ending with ']'
      
    if(lines[0]==""){
        lines.shift();
    }
    res.send(lines);
  } catch (error) {
    res.status(500).send({ error: 'Internal Server Error' });
  }
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
