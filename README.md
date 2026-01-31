# <img src="https://raw.githubusercontent.com/csihda/adamant/6b2a50dff162b0fc7af0dc6873d7e9d34cfa93aa/src/assets/adamant-header-5.svg" alt="Adamant Logo" style="width:45%;"/> <img src="frontend/assets/EMPI_Logo_reactive-fluids_Color_Black.png" alt="EMPI-RF Logo" style="width:45%;"/>

Adamant 2.0 is a JSON schema-based metadata creation tool presented in a user-friendly interface. It is designed to streamline research expirements data management (RDM) workflows, particularly for small independent laboratories, enabling the generation of research data that adheres to the FAIR (Findable, Accessible, Interoperable, Reusable) principles.

Adamant 2.0 introduces significant improvements, including enhanced deployment options, automation scripts, and multi-machine support for advanced workflows.

## Features

- Rendering of interactive web forms based on valid JSON schemas
- User-friendly editing of rendered web forms and corresponding schemas
- Creation of JSON schemas and web forms from scratch
- Live validation for various field types
- Quick reuse of existing schemas from a list
- Downloadable JSON schemas and form data
- API-based integration for form submission functionalities
- Multi-machine support for advanced workflows
- Automation scripts for deployment and maintenance

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/csihda/adamant/blob/main/LICENSE)

---

## Changelog

### [2.0.0] Major Release - July 2, 2025
#### Added
- Multi-machine deployment support
- Automation scripts for deployment and cron job setup
- Integration with Nextcloud for data preprocessing
- Dockerized setup for both frontend and backend
- Enhanced database and API configuration options

#### Changed
- Updated installation and deployment processes
- Improved schema editing and validation features
- Optimized frontend and backend performance

---

## Supported JSON Schema Keywords

Adamant 2.0 supports JSON schemas with specification versions draft 4 and 7. Below is the list of implemented keywords:

| Field Type | Implemented Keywords | Notes |
|------------|-----------------------|-------|
| String     | `title`, `id`, `$id`, `description`, `type`, `enum`, `contentEncoding`, `default`, `minLength`, `maxLength` | `contentEncoding` supports `"base64"` |
| Number     | `title`, `id`, `$id`, `description`, `type`, `enum`, `default`, `minimum`, `maximum` | |
| Integer    | `title`, `id`, `$id`, `description`, `type`, `enum`, `default`, `minimum`, `maximum` | |
| Boolean    | `title`, `id`, `$id`, `description`, `type`, `default` | |
| Array      | `title`, `id`, `$id`, `description`, `type`, `default`, `items`, `minItems`, `maxItems`, `uniqueItems` | |
| Object     | `title`, `id`, `$id`, `description`, `type`, `properties`, `required` | |



## Development

### Setting Up Adamant Locally

1. Clone the repository:
   ```bash
   git clone https://github.com/csihda/adamant.git
   cd adamant

2. Install frontend dependencies:
    ```bash
    npm install

3. Setup the backend:
    ```bash
    cd backend
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt

4. Start the backend:
    ```bash
    gunicorn -b :5000 api:app

5. Start the frontend:
    ```bash
    cd frontend
    npm start

By default, Frontend is accessible at http://localhost:3000.


## Multi-Machine Deployment

### Adamant 2.0 supports deployment across two machines:

* Machine 1: Hosts the Adamant web application (React frontend, Flask backend, MariaDB database).

* Machine 2: Hosts a Nextcloud instance and handles data preprocessing.

Refer to the Installation Guide for detailed instructions.
