# Use the latest Alpine Linux base image
FROM alpine:latest

# Install wget and bash
RUN apk update && apk add --no-cache bash && rm -rf /var/cache/apk/*

# Set the working directory
WORKDIR /app

# Download the script and make it executable
RUN wget -q https://raw.githubusercontent.com/Feriman22/freednsupdater/main/freednsupdater.sh -O freednsupdater.sh && chmod +x freednsupdater.sh

# When the container starts, run the script
CMD ["/app/freednsupdater.sh"]
