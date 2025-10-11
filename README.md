# Spotify API Client
Project to gather useful information from <a href="https://developer.spotify.com/documentation/web-api">Spotify API</a>

## Resources
* Tracks

## Elements
* **Track information**
  - Spotify ID of the Song
  - Song Name
  - Spotify URI
  - Popularity
  - Known external URLs for the track
* **Track with artist information**
  - Spotify ID of the Artist
  - Artist Name
  - Known external URLs for this artist
* **Track with album information**
  - Spotify ID of the Album
  - Album Name
  - Known external URLs for this album
  - The source URL of the image


## Entities
| Entity     | Elements                                           |
| :--------- | :------------------------------------------------- |
| **Track**  | `id`, `name`, `uri`, `popularity`, `external_url`  |
| **Artist** | `id`, `name`, `external_url`                       |
| **Album**  | `id`, `name`, `external_url`, `image`              |


# Install
## Setting up this script
* Sign up for or log in to your **Spotify for Developers** account, create a new project, and obtain your `client_id` and `client_secret`
* Copy `config/secrets_example.yml` to `config/secrets.yml` and update token
* Ensure correct version of Ruby install (see `.ruby-version` for `rbenv`)
* Run `bundle install`

# Befor Testing
To create fixtures, run:
<pre><code>ruby lib/lingo_beats.rb </code></pre>
Fixture data should appear in `spec/fixtures/` folder

Setting up VCR and WebMock for Testing

This project uses VCR and WebMock to record and mock external API requests during testing.
Before running any tests, make sure the test environment is properly configured.

1. Install test gems

By default, Bundler only installs gems from the :default and :development groups.
To include test gems such as VCR and WebMock, run:

<pre><code>
bundle config set with 'test'
bundle install
</code></pre>

(You only need to run the first command once — it will be remembered for future installs.)

If you prefer a one-time setup, you can instead run:

<pre><code>bundle install --with test</code></pre>

2. Run tests

Once installed, you can run individual test files like:

<pre><code>bundle exec ruby spec/spotify_api_spec.rb</code></pre>

3. About VCR cassettes

The first time a test runs, VCR will record real API responses into the directory:

<pre><code>spec/cassettes/</code></pre>


Subsequent runs will use the recorded responses, allowing tests to pass without making real API calls.