# Spotify API Client
Project to gather useful information from <a href="https://developer.spotify.com/documentation/web-api">Spotify API</a>

## Resources
* Tracks

## Elements
* **Track information**
  - Spotify ID of the Song
  - Song Name
  - Spotify URI
  - Known external URLs for the track
* **Track with artist information**
  - Spotify ID of the Artist
  - Artist Name
  - Known external URLs for this artist
* **Track with album information**
  - Spotify ID of the Album
  - Album Name
  - Known external URLs for this album
  - The source URL of the album image


## Entities
| Entity     | Elements                                           |
| :--------- | :------------------------------------------------- |
| **Song**  | `id`, `name`, `uri`, `external_url`, <br>`artist_id`, `artist_name`, `artist_url`, <br>`album_id`, `album_name`, `album_url`, `album_image_url`                |

# Install
## Setting up this script
* Sign up for or log in to your **Spotify for Developers** account, create a new project, and obtain your `client_id` and `client_secret`
* Copy `config/secrets_example.yml` to `config/secrets.yml` and update token
* Ensure correct version of Ruby install (see `.ruby-version` for `rbenv`)
* Run `bundle install`

## Running Tests
To run test:
<pre><code>rake spec</pre></code>