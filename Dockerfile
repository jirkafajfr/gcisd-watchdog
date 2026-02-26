FROM alpine:3.19

# Install dependencies
RUN apk add --no-cache \
    mkvtoolnix \
    opus-tools \
    sox \
    git \
    build-base \
    cmake \
    wget

# Install whisper.cpp
WORKDIR /opt
RUN git clone https://github.com/ggerganov/whisper.cpp.git && \
    cd whisper.cpp && \
    make

# Add whisper-cli to PATH
ENV PATH="/opt/whisper.cpp/build/bin:${PATH}"

# Create working directories
RUN mkdir -p /app/videos /app/transcripts /app/models /app/scripts /app/gpt

# Download the whisper model from Hugging Face
RUN wget -P /app/models https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en-q5_1.bin

# Set working directory
WORKDIR /app/videos

# Copy scripts
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Default command
CMD ["/app/scripts/transcribe.sh"]
