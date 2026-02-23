# Use the latest Alpine Linux base image
FROM alpine:latest

# Install wget and bash
RUN apk update && apk add --no-cache wget bash

# Set the working directory
WORKDIR /app

# Copy the script and make it executable
COPY freednsupdater.sh .
RUN chmod +x freednsupdater.sh

# When the container starts, run the script
CMD ["/app/freednsupdater.sh"]
