ARG ELK_VERSION

# https://www.docker.elastic.co/
# FROM docker.elastic.co/elasticsearch/elasticsearch:${ELK_VERSION}
FROM docker.elastic.co/elasticsearch/elasticsearch:6.7.1

# 여기에 ELASTIC SEARCH의 추가 PLUGIN 을 추가 해 주면 된다
# Example: RUN elasticsearch-plugin install analysis-icu