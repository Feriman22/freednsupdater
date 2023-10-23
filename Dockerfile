# Use the latest Alpine Linux base image
FROM alpine:latest

# Install curl and bash
RUN apk update && apk add --no-cache curl bash

# Set the working directory
WORKDIR /app

# Copy the startup script
COPY startup.sh /app/startup.sh

# Give execute permission to the startup script
RUN chmod +x /app/startup.sh

# When the container starts, run the startup script
CMD ["/app/startup.sh"]
