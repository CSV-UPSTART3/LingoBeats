## **LingoBeats**

An application that transforms *songs* into AI-generated content for an engaging language-learning experience.

## **Overview**

LingoBeats will connect to **Spotify** to retrieve songs and **Genius** to fetch lyrics, then analyzes the text using **Zipf frequency** and **CEFR levels** to match content with each learner’s proficiency. 

Leveraging **Wordnik**, it enriches users’ vocabulary understanding through contextual meanings and usage examples. 

Finally, **Gemini AI** generates personalized learning contents and exercises based on the linguistic insights extracted from the previous stages.

By combining music, AI, and intelligent content generation, LingoBeats hopes to turn passive listening into an interactive and personalized learning journey, boosting learners’ motivation.

## **Objectives**

### Short-term usability goals

1. Integrate Spotify and Genius APIs to retrieve and preprocess song and lyric data
2. Analyze word with Zipf, CEFR levels and Wordnik API
3. Get personalized learning materials using Gemini AI

### Long-term goals

1. Expand the platform to support multiple languages and cross-cultural learning
2. Build adaptive learning models that personalize content based on learner progress

## **Running Tests**

### To run tests：

<pre><code>rake spec</pre></code>

### To test code quality：

<pre><code>rake quality:all</pre></code>

### To run the app：
<pre><code>rake app:run</pre></code>