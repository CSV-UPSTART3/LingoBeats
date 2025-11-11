import re
import nltk
import spacy
import contractions
from nltk.corpus import stopwords

nltk.download('stopwords', quiet = True)
STOP_WORDS = set(stopwords.words('english'))
# print(STOP_WORDS)
# nlp = spacy.load("en_core_web_sm")

# 常見前綴省略對照表
LEADING_APOSTROPHE_MAP = {
    "'bout": "about",
    "’bout": "about",
    "'cause": "because",
    "’cause": "because",
    "'em": "them",
    "’em": "them",
    "'til": "until",
    "’til": "until",
    "'round": "around",
    "’round": "around"
}

# 正規化前綴撇號
def normalize_leading_apostrophe(word):
    # 若有直接在字典中對應
    if word.lower() in LEADING_APOSTROPHE_MAP:
        return LEADING_APOSTROPHE_MAP[word.lower()]

    # 否則處理像 ’neath → beneath 這類通用情形
    return re.sub(r"^[’']([a-z]+)$", r"\1", word)

def normalize_apostrophe_endings(word):
    return re.sub(r"([a-zA-Z]+)in'$", r"\1ing", word)

def preprocess(words):
    """Expand contractions and remove stopwords"""
    cleaned = []
    for word in words:
        expanded = contractions.fix(word) # e.g. you're -> you are
        # print(expanded)
        for sub in expanded.split(): # 拆成 ["you", "are"]
            sub = normalize_leading_apostrophe(sub)
            # Handle words like hidin'
            sub = normalize_apostrophe_endings(sub)
            if sub.lower() not in STOP_WORDS:
                cleaned.append(sub.lower())

            # Lemmatize
            # lemma = nlp(sub)[0].lemma_
            # if lemma.lower() not in STOP_WORDS:
            #     cleaned.append(lemma.lower())
    return cleaned

if __name__ == "__main__":
    # print(preprocess(["you're"]))
    print(normalize_apostrophe_endings("hidin'"))
    print(normalize_leading_apostrophe("'bout"))