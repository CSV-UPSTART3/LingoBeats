# Spotify API Client
Project to gather useful information from <a href="https://developer.spotify.com/documentation/web-api">Spotify API</a>

## Resources
### `GET /search`

| Param | Required | Description |
|--------|-----------|-------------|
| `q` | ✅ | Your search query (e.g., `"Adele"`). Supports field filters, e.g. `track:Hello artist:Adele year:2015`. |
| `type` | ✅ | The type of item to search for. Allowed values: `"album"`, `"artist"`, `"playlist"`, `"track"`, `"show"`, `"episode"`, `"audiobook"`. |
| `market` |  | ISO 3166-1 alpha-2 country code. If specified, only content available in that market will be returned. |
| `limit` |  | The maximum number of results to return per item type. Default: `20`. Range: `0–50`. |
| `offset` |  | The index of the first result to return (used for pagination). Default: `0`. Range: `0–1000`. |
| `include_external` |  | `audio` → Marks externally hosted audio content as playable in the response. Default: unplayable. |


## Elements

## Entities