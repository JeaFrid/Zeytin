String helloWorldHTML = """
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Revani Server</title>
          <style>
              body {
                  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                  background-color: #f9fafb;
                  color: #1f2937;
                  display: flex;
                  justify-content: center;
                  align-items: center;
                  height: 100vh;
                  margin: 0;
              }
              .container {
                  text-align: center;
                  background: white;
                  padding: 3rem;
                  border-radius: 1rem;
                  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
                  max-width: 400px;
                  width: 90%;
              }
              h1 {
                  font-size: 2.5rem;
                  margin-bottom: 0.5rem;
                  color: #d97706;
              }
              .tagline {
                  font-size: 1.1rem;
                  color: #4b5563;
                  margin-bottom: 2rem;
              }
              .status {
                  display: inline-flex;
                  align-items: center;
                  background-color: #d1fae5;
                  color: #065f46;
                  padding: 0.5rem 1rem;
                  border-radius: 9999px;
                  font-weight: 600;
                  font-size: 0.875rem;
              }
              .dot {
                  height: 8px;
                  width: 8px;
                  background-color: #059669;
                  border-radius: 50%;
                  margin-right: 0.5rem;
              }
              .footer {
                  margin-top: 2rem;
                  font-size: 0.75rem;
                  color: #9ca3af;
              }
          </style>
      </head>
      <body>
          <div class="container">
              <h1>Zeytin🫒</h1>
              <p class="tagline">Developed for humanity by <strong>JeaFriday</strong></p>
              <div class="status">
                  <span class="dot"></span>
                  All Systems Operational
              </div>
              <p class="footer">Serving delicious data since 2026</p>
          </div>
      </body>
      </html>
""";