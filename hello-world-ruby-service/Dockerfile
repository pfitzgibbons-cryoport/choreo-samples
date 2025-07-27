FROM ruby:3.3-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock* ./
RUN bundle install

# Copy the application code
COPY . .

# Expose the port
EXPOSE 8080

# Set environment variables
ENV PORT=8080
ENV RACK_ENV=production

# Start the application
CMD ["ruby", "app.rb"]
