{
  "swagger": "2.0",
  "info": {
    "title": "IRONSCALES Management API",
    "description": "<h3 style=\"font-weight: bolder\">General Error Responses:</h3>\n<table>\n    <thead>\n        <tr>\n            <td width=\"200px\">HTTP Status Codes</td>\n            <td>Reason</td>\n        </tr>\n    </thead>\n    <tbody>\n        <tr>\n            <td>400</td>\n            <td>Not authenticated</td>\n        </tr>\n        <tr>\n            <td>403</td>\n            <td>Insufficient rights to call this procedure</td>\n        </tr>\n        <tr>\n            <td>429</td>\n            <td>Too many requests (Throttling) the limit is 120 API calls per minute per company</td>\n        </tr>\n    </tbody>\n</table>",
    "termsOfService": "https://staticmediafiles.s3.amazonaws.com/static/webapp/docs/IronScalesTermsnService.pdf",
    "contact": {
      "email": "support@ironscales.com"
    },
    "securityDefinitions": {
      "Bearer": {
        "type": "JWT",
        "name": "Authorization",
        "in": "header"
      }
    },
    "version": "v1"
  },
  "host": "appapi.ironscales.com",
  "schemes": [
    "https"
  ],
  "basePath": "/appapi",
  "consumes": [
    "application/json"
  ],
  "produces": [
    "application/json"
  ],
  "securityDefinitions": {
    "JWT": {
      "type": "apikey",
      "name": "Authorization",
      "in": "header"
    }
  },
  "security": [
    {
      "JWT": []
    }
  ],
  "paths": {
    "/get-token/": {
      "post": {
        "operationId": "get JWT token",
        "description": "Get JWT used for interacting with the other endpoints of the AppAPI <br />\nCompany Key can be found under Settings -> General -> \"Company Token\"",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/JwtRequest"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successfully Response",
            "examples": {
              "application/json": {
                "jwt": "<token>"
              }
            }
          },
          "400": {
            "description": "Missing scope list under \"scopes\"",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "One of the following:<ul><li>No company found for API key</li><li>API permission disabled</li><li>Company does not have permission for requested scopes</li>",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          }
        },
        "tags": [
          "Authorization"
        ]
      },
      "parameters": []
    },
    "/campaigns/{company_id}/details": {
      "get": {
        "operationId": "Get campaigns details",
        "description": "Get campaigns details <br/>\nEach page contains 25 campaigns results<br/>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.view</li>\n    <li>company.view</li>\n</ul>\n\nStatuses mapping to UI values:\n<ul>\n    <li>Draft (0) -> Draft</li>\n    <li>Collecting (1) -> Active</li>\n    <li>Closed (2) -> Completed</li>\n    <li>Approved by User (3) -> Pending</li>\n    <li>Sending (4) -> Active</li>\n    <li>Inactive (5) -> Inactive</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "Company ID",
            "type": "integer",
            "required": true
          },
          {
            "name": "period",
            "in": "query",
            "description": "<p>Applied over campaign creation date</p>\n                                <ul>\n                                <li>0 - Last 24 hours</li>\n                                <li>1 - Last 7 days</li>\n                                <li>2 - Last 90 days</li>\n                                <li>3 - Last 180 days</li>\n                                <li>4 - Last 360 days</li>\n                                <li>5 - Current year to date</li>\n                                <li>6 - All time</li>\n                                </ul>\n",
            "required": true,
            "type": "integer"
          },
          {
            "name": "status",
            "in": "query",
            "description": "<ul>\n                                <li>0 - Draft</li>\n                                <li>1 - Collecting</li>\n                                <li>2 - Closed</li>\n                                <li>3 - Approved</li>\n                                <li>4 - Sending</li>\n                                </ul>\n                                <p>Can be multiple statuses: status=0&status=2&status=3...</p>\n",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer"
            },
            "default": [
              2
            ]
          },
          {
            "name": "page",
            "in": "query",
            "description": "Page number",
            "required": false,
            "type": "integer",
            "default": 1
          },
          {
            "name": "name",
            "in": "query",
            "description": "Optional, search by partial campaign name",
            "required": false,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "Successfully Response",
            "schema": {
              "$ref": "#/definitions/CampaignDetailsPage"
            }
          },
          "400": {
            "description": "Missing or wrong period",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company or campaign does not exist"
          }
        },
        "consumes": [],
        "tags": [
          "Campaigns"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/campaigns/{company_id}/participants-actions/": {
      "put": {
        "operationId": "Perform participants action",
        "description": "Perform action on campaign participants.<br/><b>Scopes:</b><ul><li>partner.company.edit</li><li>company.edit</li></ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/ParticipantsActionsRequest"
            }
          },
          {
            "name": "campaign_id",
            "in": "query",
            "description": "Campaign ID",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successfully updated",
            "schema": {
              "type": "object",
              "properties": {
                "success": {
                  "description": "Indicates if the action was successful",
                  "type": "boolean"
                }
              }
            }
          },
          "400": {
            "description": "Invalid request",
            "examples": {
              "application/json": {
                "message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "413": {
            "description": "Too many emails",
            "examples": {
              "application/json": {
                "message": "The emails list exceeds the maximum allowed limit of 300."
              }
            }
          }
        },
        "tags": [
          "Campaigns"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/campaigns/{company_id}/participants-details": {
      "get": {
        "operationId": "Get campaign participants details",
        "description": "Get campaign participants details <br/>\nEach page contains 100 participants<br/>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.view</li>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "Company ID",
            "type": "integer",
            "required": true
          },
          {
            "name": "campaign_id",
            "in": "query",
            "description": "Campaign ID",
            "required": true,
            "type": "integer"
          },
          {
            "name": "page",
            "in": "query",
            "description": "Page number",
            "required": false,
            "type": "integer",
            "default": 1
          }
        ],
        "responses": {
          "200": {
            "description": "Successfully Response",
            "schema": {
              "$ref": "#/definitions/CampaignParticipantsDetailsPage"
            }
          },
          "400": {
            "description": "Missing or a wrong Campaign",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company or page not found"
          }
        },
        "tags": [
          "Campaigns"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/company/create/": {
      "post": {
        "operationId": "Create a new company",
        "description": "Create new company\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.create</li>\n</ul>\n<b>Plan types::</b>\n<ul>\n    <li>1 - Phishing Simulation and Training</li>\n    <li>7 - SAT Suite</li>\n    <li>2 - Starter</li>\n    <li>3 - Core</li>\n    <li>4 - Email Protect</li>\n    <li>5 - Complete Protect</li>\n    <li>6 - Ironscales Protect</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/CreateCompany"
            }
          }
        ],
        "responses": {
          "201": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/CreateCompanyResponse"
            }
          },
          "400": {
            "description": "Validation Errors",
            "examples": {
              "application/json": [
                {
                  "ownerEmail": [
                    "Email test@example.com already registered"
                  ]
                },
                {
                  "country": [
                    "\"test\" is not a recognized country name"
                  ]
                }
              ]
            }
          },
          "403": {
            "description": "No permissions"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "parameters": []
    },
    "/company/list/": {
      "get": {
        "operationId": "List a partner companies",
        "description": "List partner companies\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "name",
            "in": "query",
            "description": "Optional: filter companies by name",
            "required": false,
            "type": "string"
          },
          {
            "name": "domain",
            "in": "query",
            "description": "Optional: filter companies by domain",
            "required": false,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/CompanyList"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "parameters": []
    },
    "/company/list/v2/": {
      "get": {
        "operationId": "List a partner companies V2",
        "description": "List partner companies\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "description": "Page Number",
            "required": false,
            "type": "integer",
            "default": 1
          },
          {
            "name": "name",
            "in": "query",
            "description": "Optional: filter companies by name",
            "required": false,
            "type": "string",
            "minLength": 1
          },
          {
            "name": "domain",
            "in": "query",
            "description": "Optional: filter companies by domain",
            "required": false,
            "type": "string",
            "minLength": 1
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/CompanyListV2Response"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "parameters": []
    },
    "/company/{company_id}": {
      "get": {
        "operationId": "Get a company by id",
        "description": "Get a company by id\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.view</li>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/Company"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "put": {
        "operationId": "Update a company by id",
        "description": "Update a company by id\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.edit</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/Company"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/Company"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "delete": {
        "operationId": "Disable a company by id",
        "description": "Disable a company by id\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.edit</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/EmptyResponse"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/company/{company_id}/911-email/": {
      "get": {
        "operationId": "Get a company 911 email information",
        "description": "Get a company's 911 email information\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/CompanyEmail911"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company found matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "post": {
        "operationId": "Update a company 911 email settings",
        "description": "Enable a company's 911 email configuration\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/CompanyEmail911"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "type": "object",
              "properties": {
                "email": {
                  "type": "string"
                },
                "is_enabled": {
                  "type": "boolean"
                },
                "message": {
                  "type": "string"
                }
              }
            }
          },
          "400": {
            "description": "Invalid email address or configuration error"
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company found matching the query"
          },
          "500": {
            "description": "Unexpected server error"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "delete": {
        "operationId": "Delete a company 911 email configuration",
        "description": "Delete/disable a company's 911 email configuration\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "type": "object",
              "properties": {
                "message": {
                  "type": "string"
                }
              }
            }
          },
          "400": {
            "description": "Configuration error or no email integration"
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company found matching the query"
          },
          "500": {
            "description": "Unexpected server error"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/company/{company_id}/auto-sync/": {
      "get": {
        "operationId": "Get Auto-Sync status",
        "description": "Get the status of the Auto-Sync\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.view</li>\n</ul>",
        "parameters": [],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/AutoSyncStatusResponse"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "post": {
        "operationId": "Activate Auto-Sync",
        "description": "Activate Auto-Sync\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.edit</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/ActivateAutoSyncRequest"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/EmptyResponse"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "delete": {
        "operationId": "Disable Auto-Sync",
        "description": "Disable Auto-Sync\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.edit</li>\n</ul>",
        "parameters": [],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/EmptyResponse"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/company/{company_id}/auto-sync/groups/": {
      "get": {
        "operationId": "Get Auto-Sync Groups",
        "description": "Get Auto-Sync Groups\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "description": "Page number",
            "required": false,
            "type": "integer",
            "default": 1
          },
          {
            "name": "query",
            "in": "query",
            "description": "Optional: filter groups by name",
            "required": false,
            "type": "string"
          },
          {
            "name": "gd_admin_email",
            "in": "query",
            "description": "Required for Google: admin email",
            "required": false,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/AutoSyncGroupsResponse"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/company/{company_id}/auto-sync/mailboxes/": {
      "get": {
        "operationId": "Get company synced emails",
        "description": "Get Auto-Sync emails\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "required": false,
            "type": "integer",
            "default": 1
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/AutoSyncEmailListResponse"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/company/{company_id}/features/": {
      "get": {
        "operationId": "Get a company features states access",
        "description": "Get a company features States access\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.edit</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/GetCompanyFeature"
            }
          },
          "400": {
            "description": "Missing company id",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "put": {
        "operationId": "Update a company features states access",
        "description": "Update company features States access<br/>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.edit</li>\n</ul>\n<b>Available features:</b>\n<ul>\n    <li>API</li>\n    <li>silentMode</li>\n    <li>silentModeMsg</li>\n    <li>themiscopilot</li>\n    <li>ATO</li>\n    <li>serviceManagement</li>\n    <li>trainingCampaignsWizer</li>\n    <li>attachmentsScan</li>\n    <li>linksScan</li>\n    <li>SATBundlePlus</li>\n    <li>dmarcManagement</li>\n    <li>autopilot</li>\n</ul>\n<b>State:</b> <ul><li>enable</li><li>disable</li></ul>\n<b>Body example</b>\n<br/><p>\n[\n<br>&nbsp;&nbsp;&nbsp;{\n<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\"feature\":\"silentmode\",\n<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\"state\":\"disable\"\n<br>&nbsp;&nbsp;&nbsp;},\n<br>&nbsp;&nbsp;&nbsp;{\n<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\"feature\": \"****\",\n<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\"state\":\"disable\"\n<br>&nbsp;&nbsp;&nbsp;}\n<br>]\n</p>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/UpdateCompanyFeature"
              }
            }
          },
          "400": {
            "description": "Missing company id or wrong request",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/company/{company_id}/manifest/": {
      "post": {
        "operationId": "Generate OWA Manifest for Company",
        "description": "Generate OWA (Outlook Web App) Manifest XML for a company\nThis endpoint generates an XML manifest file for the Outlook Web App add-in.\nThe manifest contains customized settings based on the provided data.\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/CompanyManifestGenerator"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "Company ID to generate manifest for",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response - Returns XML manifest file",
            "schema": {
              "type": "string",
              "format": "binary"
            }
          },
          "400": {
            "description": "Input data validation failure",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company not found"
          }
        },
        "produces": [
          "application/xml",
          "application/json"
        ],
        "tags": [
          "Company"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/company/{company_id}/stats/": {
      "get": {
        "operationId": "Get a company statistics and license",
        "description": "Get company statistics and license\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.view</li>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/CompanyDetails"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Company"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/emails/{company_id}/": {
      "get": {
        "operationId": "List of escalated emails",
        "description": "<b>Rate Limit</b>: 20 requests per minute<br /><b>Scopes:</b><ul><li>company.view</li></ul>",
        "parameters": [
          {
            "name": "start_time",
            "in": "query",
            "description": "iso-8601 format",
            "required": false,
            "type": "string",
            "format": "date-time",
            "x-nullable": true
          },
          {
            "name": "end_time",
            "in": "query",
            "description": "iso-8601 format",
            "required": false,
            "type": "string",
            "format": "date-time",
            "x-nullable": true
          },
          {
            "name": "page",
            "in": "query",
            "required": false,
            "type": "integer",
            "default": 1,
            "minimum": 1
          },
          {
            "name": "page_size",
            "in": "query",
            "required": false,
            "type": "integer",
            "default": 50,
            "maximum": 300000,
            "minimum": 1
          },
          {
            "name": "recipient",
            "in": "query",
            "required": false,
            "type": "string",
            "x-nullable": true
          },
          {
            "name": "threat_type",
            "in": "query",
            "description": "0 - VIP Impersonation, 1 - Business Email Compromise, 2 - Financial Fraud, 3 - Gift Card Request, 4 - Fraudulent Request, 5 - Credential Theft, 6 - Advance-fee Scam, 7 - Lottery Scam, 8 - Extortion, 9 - Sextortion, 10 - Vishing Attack, 11 - Vendor Scam, 12 - Invoice Phishing, 13 - Vendor Email Compromise, 14 - Suspected Malicious Content, 15 - Polymorphic Phishing, 16 - Bulk Phishing, 17 - Image-Based Attack, 18 - QR Code Attack, 19 - Vendor Scam",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer",
              "enum": [
                0,
                1,
                2,
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                12,
                13,
                14,
                15,
                16,
                17,
                18,
                19
              ]
            },
            "x-nullable": true
          },
          {
            "name": "classification",
            "in": "query",
            "description": "0 - Phishing, 1 - Spam, 2 - Safe, 3 - Unclassified, 4 - Microsoft quarantine, 5 - Released from Microsoft",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer",
              "enum": [
                0,
                1,
                2,
                3,
                4,
                5
              ]
            },
            "x-nullable": true
          },
          {
            "name": "is_scanback_report",
            "in": "query",
            "required": false,
            "type": "boolean",
            "x-nullable": true
          },
          {
            "name": "incident_id",
            "in": "query",
            "required": false,
            "type": "integer",
            "x-nullable": true
          },
          {
            "name": "challenged_type",
            "in": "query",
            "description": "Filter by challenge type. Options: release_request, end_user_report",
            "required": false,
            "type": "string",
            "enum": [
              "release_request",
              "end_user_report"
            ]
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/EmailsResponse"
            }
          },
          "400": {
            "description": "Validation Errors",
            "examples": {
              "application/json": {
                "non_field_errors": [
                  "Provide incident_id or both start_time and end_time"
                ],
                "threat_type": {
                  "0": "\"99\" is not a valid choice."
                },
                "classification": {
                  "0": "\"99\" is not a valid choice."
                }
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          }
        },
        "tags": [
          "Emails"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/incident/{company_id}/account-takeover/{incident_id}/details/": {
      "get": {
        "operationId": "Get Account Takeover incident details",
        "description": "\nRetrieve detailed information about a specific Account Takeover incident.\n<br/><br/>\n<b>Query Parameters:</b>\n<ul>\n    <li><b>page:</b> Page number for pagination (default: 1)</li>\n    <li><b>items_per_page:</b> Number of items per page (min: 1, max: 500, default: 50)</li>\n    <li><b>title:</b> Filter by alert titles (can specify multiple)</li>\n    <li><b>location:</b> Filter by locations (can specify multiple)</li>\n    <li><b>ip:</b> Filter by IP addresses with validation (can specify multiple)</li>\n</ul>\n<br/><b>Response Data:</b>\n<ul>\n    <li><b>incident_details:</b> Complete incident information with account details and alerts</li>\n    <li><b>filter_options:</b> Available filter values for dropdown menus</li>\n    <li><b>pagination:</b> Page count and current page information</li>\n</ul>\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.view</li>\n</ul>\n",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "description": "Page number for pagination results. Starts at 1.",
            "required": false,
            "type": "integer",
            "default": 1,
            "minimum": 1
          },
          {
            "name": "items_per_page",
            "in": "query",
            "description": "Number of items per page. Min: 1, Max: 500, Default: 50.",
            "required": false,
            "type": "integer",
            "default": 50,
            "maximum": 500,
            "minimum": 1
          },
          {
            "name": "title",
            "in": "query",
            "description": "List of alert titles to filter by.",
            "required": false,
            "type": "array",
            "items": {
              "type": "string",
              "maxLength": 200,
              "minLength": 1
            }
          },
          {
            "name": "location",
            "in": "query",
            "description": "List of locations to filter by.",
            "required": false,
            "type": "array",
            "items": {
              "type": "string",
              "maxLength": 200,
              "minLength": 1
            }
          },
          {
            "name": "ip",
            "in": "query",
            "description": "List of IPv4 or IPv6 addresses to filter by.",
            "required": false,
            "type": "array",
            "items": {
              "type": "string",
              "minLength": 1
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successfully retrieved Account Takeover incident details.",
            "schema": {
              "$ref": "#/definitions/AccountTakeoverDetailsResponse"
            },
            "examples": {
              "application/json": {
                "incident_details": {
                  "id": 123,
                  "account_details": {
                    "name": "John Doe",
                    "email": "john.doe@company.com",
                    "title": "Manager",
                    "department": "IT Security",
                    "country": "United States",
                    "phone_number": "+1-555-0123"
                  },
                  "alerts": [
                    {
                      "id": 456,
                      "title": "Suspicious Login",
                      "description": "Login from unusual location detected",
                      "type": 1,
                      "details": [
                        {
                          "ip": "127.0.0.0",
                          "location": "New York, NY",
                          "logon_time": "2024-01-15T10:30:00Z"
                        }
                      ],
                      "created": "2024-01-15T10:25:00Z"
                    }
                  ],
                  "state": 1,
                  "original_state": 1,
                  "resolved_by": "Jane Smith",
                  "resolved_on": "2024-01-15T14:30:00Z",
                  "created": "2024-01-15T10:25:00Z",
                  "assignee": {
                    "id": 789,
                    "email": "security@company.com",
                    "first_name": "Security",
                    "last_name": "Team"
                  }
                },
                "filter_options": {
                  "titles": [
                    "Suspicious Login",
                    "Rule Created"
                  ],
                  "locations": [
                    "New York",
                    "California"
                  ],
                  "ips": [
                    "127.0.0.0",
                    "127.0.0.1"
                  ]
                },
                "pages_count": 3,
                "page": 1,
                "items_per_page": 50
              }
            }
          },
          "400": {
            "description": "Invalid query parameters - validation errors",
            "examples": {
              "application/json": {
                "page": [
                  "Ensure this value is greater than or equal to 1."
                ],
                "ip": [
                  "Enter a valid IPv4 or IPv6 address."
                ]
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          }
        },
        "tags": [
          "Incident"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        },
        {
          "name": "incident_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/incident/{company_id}/account-takeover/{incident_id}/remediation/": {
      "post": {
        "operationId": "Create Account Takeover remediation",
        "description": "\nCreate remediation for the specified Account Takeover incident.\n<br/><br/>\n<b>State Options:</b>\n<ul>\n    <li><b>2 (Safe):</b> Mark the incident as safe/false positive</li>\n    <li><b>3 (Compromised):</b> Mark the incident as compromised and apply remediation actions</li>\n</ul>\n<br/><b>Remediation Actions:</b>\n<ul>\n    <li><b>3 (SIGN_OUT):</b> Revoke user's Microsoft 365 sessions - only allowed for state 3 (Compromised)</li>\n    <li><b>4 (DISABLE_ACCOUNT):</b> Disable user's Microsoft 365 account - only allowed for state 3 (Compromised)</li>\n</ul>\n<br/><b>Validation Rules:</b>\n<ul>\n    <li>Remediation actions can only be applied when marking incident as compromised (state=3)</li>\n    <li>When marking incident as safe (state=2), no action should be provided</li>\n</ul>\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n</ul>\n",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/AccountTakeoverRemediation"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successfully updated incident state and applied remediation actions.",
            "schema": {
              "$ref": "#/definitions/AccountTakeoverRemediationResponse"
            },
            "examples": {
              "application/json": {
                "state": 3
              }
            }
          },
          "400": {
            "description": "Invalid request body - validation errors",
            "schema": {
              "$ref": "#/definitions/AccountTakeoverRemediationError"
            },
            "examples": {
              "application/json": {
                "data": {
                  "state": [
                    "This field is required."
                  ],
                  "action": [
                    "Remediation actions are only allowed when marking incident as compromised (state=3)."
                  ]
                }
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Incident"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        },
        {
          "name": "incident_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/incident/{company_id}/classify/{incident_id}": {
      "post": {
        "operationId": "Classify specific incident",
        "description": "Classify specific incident<br/><b>Scopes:</b><ul><li>partner.company.classify</li><li>company.classify</li></ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/IncidentClassification"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          },
          {
            "name": "incident_id",
            "in": "path",
            "description": "incident id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "examples": {
              "application/json": {
                "success": true
              }
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Incident/company were not found"
          }
        },
        "tags": [
          "Incident"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        },
        {
          "name": "incident_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/incident/{company_id}/details/{incident_id}": {
      "get": {
        "operationId": "Get details of specific incident",
        "description": "Get details of specific incident<br/>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.view</li>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          },
          {
            "name": "incident_id",
            "in": "path",
            "description": "incident id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/IncidentDetails"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Incident/company were not found"
          }
        },
        "tags": [
          "Incident"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        },
        {
          "name": "incident_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/incident/{company_id}/list/": {
      "get": {
        "operationId": "Get list of Incidents",
        "description": "List of Incidents\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>company.all</li>\n    <li>partner.company.view</li>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "required": false,
            "type": "integer",
            "default": 1
          },
          {
            "name": "items_per_page",
            "in": "query",
            "description": "Number of items per page (optional, overrides default)",
            "required": false,
            "type": "integer",
            "default": 100,
            "minimum": 1
          },
          {
            "name": "sort",
            "in": "query",
            "description": "Options: created | latestEmailDate | incidentID | emailSubject | senderName | senderEmail | recipientName | recipientEmail | classification | firstChallengedDate | noSorting",
            "required": false,
            "type": "string",
            "enum": [
              "created",
              "latestEmailDate",
              "incidentID",
              "emailSubject",
              "senderName",
              "senderEmail",
              "recipientName",
              "recipientEmail",
              "classification",
              "firstChallengedDate",
              "noSorting"
            ],
            "default": "noSorting"
          },
          {
            "name": "order",
            "in": "query",
            "description": "Options: desc | asc",
            "required": false,
            "type": "string",
            "enum": [
              "desc",
              "asc"
            ],
            "default": "desc"
          },
          {
            "name": "created_start_time",
            "in": "query",
            "description": "Start of created date range, ISO Date with percent encoding. For example 2025-03-18T13:45:30.635993%2B00:00",
            "required": false,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "created_end_time",
            "in": "query",
            "description": "End of created date range, ISO Date with percent encoding. For example 2025-03-18T13:45:30.635993%2B00:00",
            "required": false,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "incidentID",
            "in": "query",
            "description": "The incident ID",
            "required": false,
            "type": "integer"
          },
          {
            "name": "search_email_subject",
            "in": "query",
            "description": "Search Email Subject",
            "required": false,
            "type": "string",
            "default": ""
          },
          {
            "name": "search_sender_name",
            "in": "query",
            "description": "Search Sender Name",
            "required": false,
            "type": "string",
            "default": ""
          },
          {
            "name": "search_sender_email",
            "in": "query",
            "description": "Search Sender Email",
            "required": false,
            "type": "string",
            "default": ""
          },
          {
            "name": "search_recipient_name",
            "in": "query",
            "description": "Search Recipient Name",
            "required": false,
            "type": "string",
            "default": ""
          },
          {
            "name": "search_recipient_email",
            "in": "query",
            "description": "Search Recipient Email",
            "required": false,
            "type": "string",
            "default": ""
          },
          {
            "name": "classification",
            "in": "query",
            "description": "Options: all | phishing | spam | compromised | safe | open | silent(can select multiple by repeating fields (field1=value1&field1=value2&field1=value3...))",
            "required": false,
            "type": "array",
            "items": {
              "type": "string",
              "enum": [
                "all",
                "phishing",
                "spam",
                "compromised",
                "safe",
                "open",
                "silent"
              ]
            },
            "default": [
              "all"
            ],
            "collectionFormat": "multi"
          },
          {
            "name": "challenged_type",
            "in": "query",
            "description": "Filter by challenge type. Options: release_request, end_user_report",
            "required": false,
            "type": "string",
            "enum": [
              "release_request",
              "end_user_report"
            ]
          },
          {
            "name": "challenged_start_date",
            "in": "query",
            "description": "Start of challenged date range, ISO Date with percent encoding. For example 2025-03-18T13:45:30.635993%2B00:00",
            "required": false,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "challenged_end_date",
            "in": "query",
            "description": "End of challenged date range, ISO Date with percent encoding. For example 2025-03-18T13:45:30.635993%2B00:00",
            "required": false,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "state",
            "in": "query",
            "description": "Options: all | classified | unclassified | challenged(can select multiple by repeating fields (field1=value1&field1=value2&field1=value3...))",
            "required": false,
            "type": "array",
            "items": {
              "type": "string",
              "enum": [
                "all",
                "classified",
                "unclassified",
                "challenged"
              ]
            },
            "default": [
              "all"
            ],
            "collectionFormat": "multi"
          },
          {
            "name": "reportType",
            "in": "query",
            "description": "Options: all | email | ato | teams | msft_quarantine",
            "required": false,
            "type": "string",
            "enum": [
              "all",
              "email",
              "ato",
              "teams",
              "msft_quarantine"
            ],
            "default": "all"
          },
          {
            "name": "last_update_start_time",
            "in": "query",
            "description": "Start of last update date range, ISO Date with percent encoding. For example 2025-03-18T13:45:30.635993%2B00:00",
            "required": false,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "last_update_end_time",
            "in": "query",
            "description": "End of last update date range, ISO Date with percent encoding. For example 2025-03-18T13:45:30.635993%2B00:00",
            "required": false,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "period",
            "in": "query",
            "description": "The period to show. Deprecated in favor of created_start_time/created_end_time. Options: <br />0: Last 24 hours<br />1: Last 7 days<br />2: Last 90 days<br />3: Last 180 days<br />4: Last 360 days<br />5: Current year to date<br />6: All time",
            "required": false,
            "type": "integer",
            "enum": [
              0,
              1,
              2,
              3,
              4,
              5,
              6
            ]
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/IncidentListPage"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Incident or page were not found"
          }
        },
        "tags": [
          "Incident"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/incident/{company_id}/recluster/{incident_id}": {
      "post": {
        "operationId": "Recluster incident",
        "description": "Recluster (revert) mitigations back to the original incident they were unclustered from.<br/>\nThis reverses a previous uncluster operation by moving mitigations back to their original incident.<br/>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.company.classify</li>\n    <li>company.classify</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/ReclusterIncident"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          },
          {
            "name": "incident_id",
            "in": "path",
            "description": "incident id (the unclustered incident to recluster from)",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "examples": {
              "application/json": {
                "report_id": 12345,
                "mitigation_id": 67890,
                "count": 5,
                "newState": "Attack"
              }
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Incident/company were not found or incident was not unclustered"
          }
        },
        "tags": [
          "Incident"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        },
        {
          "name": "incident_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/incident/{company_id}/scanback-list/": {
      "get": {
        "operationId": "Get list of Scanback Incidents",
        "description": "List of Incidents\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>company.all</li>\n    <li>partner.company.view</li>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "required": false,
            "type": "integer",
            "default": 1
          },
          {
            "name": "items_per_page",
            "in": "query",
            "description": "Number of items per page (optional, overrides default)",
            "required": false,
            "type": "integer",
            "default": 100,
            "minimum": 1
          },
          {
            "name": "sort",
            "in": "query",
            "description": "Options: created | incidentID | emailSubject | senderName | senderEmail | recipientName | recipientEmail | classification | noSorting",
            "required": false,
            "type": "string",
            "enum": [
              "created",
              "incidentID",
              "emailSubject",
              "senderName",
              "senderEmail",
              "recipientName",
              "recipientEmail",
              "classification",
              "noSorting"
            ],
            "default": "noSorting"
          },
          {
            "name": "order",
            "in": "query",
            "description": "Options: desc | asc",
            "required": false,
            "type": "string",
            "enum": [
              "desc",
              "asc"
            ],
            "default": "desc"
          },
          {
            "name": "created_start_time",
            "in": "query",
            "description": "Start of created date range, ISO Date with percent encoding. For example 2025-03-18T13:45:30.635993%2B00:00",
            "required": false,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "created_end_time",
            "in": "query",
            "description": "End of created date range, ISO Date with percent encoding. For example 2025-03-18T13:45:30.635993%2B00:00",
            "required": false,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "incidentID",
            "in": "query",
            "description": "The incident ID",
            "required": false,
            "type": "integer"
          },
          {
            "name": "search_email_subject",
            "in": "query",
            "description": "Search Email Subject",
            "required": false,
            "type": "string",
            "default": ""
          },
          {
            "name": "search_sender_name",
            "in": "query",
            "description": "Search Sender Name",
            "required": false,
            "type": "string",
            "default": ""
          },
          {
            "name": "search_sender_email",
            "in": "query",
            "description": "Search Sender Email",
            "required": false,
            "type": "string",
            "default": ""
          },
          {
            "name": "search_recipient_name",
            "in": "query",
            "description": "Search Recipient Name",
            "required": false,
            "type": "string",
            "default": ""
          },
          {
            "name": "search_recipient_email",
            "in": "query",
            "description": "Search Recipient Email",
            "required": false,
            "type": "string",
            "default": ""
          },
          {
            "name": "classification",
            "in": "query",
            "description": "Options: all | phishing | spam | compromised | safe | open | silent(can select multiple by repeating fields (field1=value1&field1=value2&field1=value3...))",
            "required": false,
            "type": "array",
            "items": {
              "type": "string",
              "enum": [
                "all",
                "phishing",
                "spam",
                "compromised",
                "safe",
                "open",
                "silent"
              ]
            },
            "default": [
              "all"
            ],
            "collectionFormat": "multi"
          },
          {
            "name": "challenged_type",
            "in": "query",
            "description": "Filter by challenge type. Options: release_request, end_user_report",
            "required": false,
            "type": "string",
            "enum": [
              "release_request",
              "end_user_report"
            ]
          },
          {
            "name": "challenged_start_date",
            "in": "query",
            "description": "Start of challenged date range, ISO Date with percent encoding. For example 2025-03-18T13:45:30.635993%2B00:00",
            "required": false,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "challenged_end_date",
            "in": "query",
            "description": "End of challenged date range, ISO Date with percent encoding. For example 2025-03-18T13:45:30.635993%2B00:00",
            "required": false,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "state",
            "in": "query",
            "description": "Options: all | classified | unclassified(can select multiple by repeating fields (field1=value1&field1=value2&field1=value3...))",
            "required": false,
            "type": "array",
            "items": {
              "type": "string",
              "enum": [
                "all",
                "classified",
                "unclassified"
              ]
            },
            "default": [
              "all"
            ],
            "collectionFormat": "multi"
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/ScanBackPage"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Incident or page were not found"
          }
        },
        "tags": [
          "Incident"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/incident/{company_id}/stats/remediation-statuses/": {
      "get": {
        "operationId": "Remediation statuses stats",
        "description": "<b>Rate Limit</b>: 20 requests per second<br /><b>Scopes:</b><ul><li>company.view</li></ul>",
        "parameters": [
          {
            "name": "start_time",
            "in": "query",
            "description": "iso-8601 format",
            "required": true,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "end_time",
            "in": "query",
            "description": "iso-8601 format",
            "required": true,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "include_scanback",
            "in": "query",
            "required": false,
            "type": "boolean",
            "default": false
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/RemediationStatusesStats"
            }
          },
          "400": {
            "description": "Validation Errors",
            "examples": {
              "application/json": [
                {
                  "end_time": [
                    "This field is required."
                  ],
                  "start_time": [
                    "This field is required."
                  ]
                },
                {
                  "end_time": [
                    "Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]."
                  ],
                  "start_time": [
                    "Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]."
                  ]
                },
                {
                  "end_time": [
                    "The `end_time` must be later than the `start_time`."
                  ]
                },
                {
                  "end_time": [
                    "The time range between `start_time` and `end_time` cannot exceed 365 days."
                  ]
                },
                {
                  "include_scanback": [
                    "Must be a valid boolean."
                  ]
                }
              ]
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Incident"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/incident/{company_id}/uncluster/{incident_id}": {
      "post": {
        "operationId": "Uncluster incident",
        "description": "Uncluster mitigations from an incident to create a new incident with a different classification.<br/>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.company.classify</li>\n    <li>company.classify</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/UnclusterIncident"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          },
          {
            "name": "incident_id",
            "in": "path",
            "description": "incident id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "examples": {
              "application/json": {
                "report_id": 12345,
                "mitigation_id": 67890,
                "count": 5,
                "newState": "Attack"
              }
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Incident/company were not found"
          }
        },
        "tags": [
          "Incident"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        },
        {
          "name": "incident_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/incident/{company_id}/{status}/": {
      "get": {
        "operationId": "Get IDs list of unclassified incidents",
        "description": "Get ids of open incidents<br/>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.view</li>\n    <li>company.view</li>\n</ul>\n<br/><b>Status:</b>\n<ul><li>open</li></ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "examples": {
              "application/json": {
                "incident_ids": [
                  1,
                  2,
                  3
                ]
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Incident"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        },
        {
          "name": "status",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/integrations/o365-authorize/": {
      "post": {
        "operationId": "O365 integration authorize",
        "description": "<p><b>Integration step 2:</b> Authorize Microsoft Oauth redirect URL</p>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.company.edit</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/AdminAuthorize"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Authorized successfully",
            "examples": {
              "application/json": {
                "additional_data": "value"
              }
            }
          },
          "204": {
            "description": "Authorized successfully"
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company were not found"
          }
        },
        "tags": [
          "Integrations"
        ]
      },
      "parameters": []
    },
    "/integrations/{company_id}/disable-integration/": {
      "post": {
        "operationId": "Disable integration",
        "description": "<p>Disable active integration</p>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.company.edit</li>\n</ul>\n<p>\n    The response contains three fields:\n    <ul>\n        <li><b>company_id</b>: Ironscales company id</li>\n        <li><b>integration_type</b>: The active integration type - Office365 / GWS / Exchange</li>\n        <li><b>integration_status</b>: Disabling</li>\n    </ul>\n</p>",
        "parameters": [],
        "responses": {
          "200": {
            "description": "Integration disabled successfully",
            "examples": {
              "application/json": {
                "company_id": 0,
                "integration_type": "Office365",
                "integration_status": "Disabling"
              }
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company were not found"
          }
        },
        "tags": [
          "Integrations"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/integrations/{company_id}/gws-authorize/": {
      "post": {
        "operationId": "GWS integration authorize",
        "description": "<p><b>Integration step 2:</b> Authorize Google Workspace integration</p>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.company.edit</li>\n</ul>",
        "parameters": [],
        "responses": {
          "204": {
            "description": "Authorized successfully"
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company were not found"
          }
        },
        "tags": [
          "Integrations"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/integrations/{company_id}/gws-consent-redirect-uri/": {
      "post": {
        "operationId": "GWS generate admin consent url",
        "description": "<p><b>Integration step 1:</b> Generate the Google Workspace integration OAuth URL</p>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.company.edit</li>\n</ul>",
        "parameters": [],
        "responses": {
          "200": {
            "description": "Admin consent url generated successfully",
            "schema": {
              "$ref": "#/definitions/AdminConsentResponse"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company were not found"
          }
        },
        "tags": [
          "Integrations"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/integrations/{company_id}/integration-status/": {
      "get": {
        "operationId": "Integration status",
        "description": "<p>Get email integration type and status</p>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.company.edit</li>\n</ul>\n<p>\n    The response contains three fields:\n    <ul>\n        <li><b>company_id</b>: Ironscales company id</li>\n        <li><b>integration_type</b>: The active integration type - Office365 / GWS / Exchange</li>\n        <li><b>is_integrated</b>: true / false</li>\n    </ul>\n</p>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Integration Status provided successfully",
            "examples": {
              "application/json": {
                "company_id": 0,
                "integration_type": "Office365",
                "is_integrated": true
              }
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company were not found"
          }
        },
        "tags": [
          "Integrations"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/integrations/{company_id}/o365-consent-redirect-uri/": {
      "post": {
        "operationId": "O365 generate admin consent redirect url",
        "description": "<p><b>Integration step 1:</b> Generate the Office 365 integration admin consent redirect URL</p>\n<p>This endpoint validates the provided parameters.\nIf they are valid, Ironscales will generate a redirect URL for the Office 365 OAuth consent page.\n</p>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.company.edit</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/AdminConsent"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Oauth redirect url generated successfully",
            "schema": {
              "$ref": "#/definitions/AdminConsentResponse"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company were not found"
          }
        },
        "tags": [
          "Integrations"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/mailboxes/{company_id}/compliance-report/": {
      "get": {
        "operationId": "Get compliance report",
        "description": "Compliance report for a company per user\n<br/><b>Scopes:</b>\n<ul>\n<li>partner.all</li>\n<li>company.all</li>\n<li>partner.company.view</li>\n<li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "period",
            "in": "query",
            "description": "\nPeriod to filter the campaigns by:\n<ul>\n    <li>1 - Last 7 days</li>\n    <li>2 - Last year</li>\n    <li>3 - Last 3 month</li>\n    <li>4 - Last 6 month</li>\n    <li>5 - Custom range (up to 180d) - MM-DD-YYYY - MM-DD-YYYY</li>\n</ul>\n",
            "required": false,
            "type": "integer",
            "enum": [
              1,
              2,
              3,
              4,
              5
            ],
            "default": 3
          },
          {
            "name": "customPeriodFrom",
            "in": "query",
            "description": "Start date of the custom period in MM-DD-YYYY format",
            "required": false,
            "type": "string",
            "format": "date"
          },
          {
            "name": "customPeriodTo",
            "in": "query",
            "description": "End date of the custom period in MM-DD-YYYY format",
            "required": false,
            "type": "string",
            "format": "date"
          },
          {
            "name": "page",
            "in": "query",
            "description": "Page number",
            "required": false,
            "type": "integer",
            "default": 1
          }
        ],
        "responses": {
          "200": {
            "description": "Successfully Response",
            "schema": {
              "$ref": "#/definitions/MailboxesUserComplianceReportResponse"
            }
          }
        },
        "tags": [
          "Mailboxes"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/mailboxes/{company_id}/list/": {
      "get": {
        "operationId": "List of a company mailboxes",
        "description": "List of a company mailboxes\n<br/><b>Scopes:</b>\n<ul>\n<li>partner.all</li>\n<li>company.all</li>\n<li>partner.company.view</li>\n<li>company.view</li>\n</ul>\n\nAll filters with string values are case-insensitive",
        "parameters": [
          {
            "name": "ids",
            "in": "query",
            "description": "List of mailbox ids",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          {
            "name": "exclude_ids",
            "in": "query",
            "description": "List of mailbox ids to exclude",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          {
            "name": "search",
            "in": "query",
            "description": "Search term to look for in first_name, last_name, title, department, email or phone_number fields",
            "required": false,
            "type": "string",
            "x-nullable": true
          },
          {
            "name": "is_enabled",
            "in": "query",
            "required": false,
            "type": "boolean",
            "x-nullable": true
          },
          {
            "name": "tags",
            "in": "query",
            "description": "Array of tag names",
            "required": false,
            "type": "array",
            "items": {
              "type": "string",
              "minLength": 1
            }
          },
          {
            "name": "first_name",
            "in": "query",
            "required": false,
            "type": "string",
            "x-nullable": true
          },
          {
            "name": "last_name",
            "in": "query",
            "required": false,
            "type": "string",
            "x-nullable": true
          },
          {
            "name": "department",
            "in": "query",
            "required": false,
            "type": "string",
            "x-nullable": true
          },
          {
            "name": "email",
            "in": "query",
            "required": false,
            "type": "string",
            "x-nullable": true
          },
          {
            "name": "title",
            "in": "query",
            "required": false,
            "type": "string",
            "x-nullable": true
          },
          {
            "name": "is_protected",
            "in": "query",
            "required": false,
            "type": "boolean",
            "x-nullable": true
          },
          {
            "name": "language",
            "in": "query",
            "description": "Language full name",
            "required": false,
            "type": "string",
            "x-nullable": true
          },
          {
            "name": "awareness",
            "in": "query",
            "description": "0 - Beginner Level, 1 - Mid Level, 2 - Expert Level",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer",
              "maximum": 2,
              "minimum": 0
            }
          },
          {
            "name": "sort",
            "in": "query",
            "required": false,
            "type": "string",
            "enum": [
              "id",
              "title",
              "department",
              "first_name",
              "last_name",
              "email",
              "awareness",
              "is_enabled",
              "language",
              "is_protected"
            ],
            "default": "id"
          },
          {
            "name": "order",
            "in": "query",
            "required": false,
            "type": "string",
            "enum": [
              "asc",
              "desc"
            ],
            "default": "asc"
          },
          {
            "name": "page",
            "in": "query",
            "description": "Page Number",
            "required": false,
            "type": "integer",
            "default": 1
          },
          {
            "name": "items_per_page",
            "in": "query",
            "description": "Number of items per page (optional, overrides default)",
            "required": false,
            "type": "integer",
            "default": 100,
            "minimum": 1
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/MailboxesPageDetails"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found or page out of range"
          }
        },
        "tags": [
          "Mailboxes"
        ]
      },
      "put": {
        "operationId": "Bulk edit of a company mailboxes",
        "description": "List of a company mailboxes\n<br/><b>Scopes:</b>\n<ul>\n<li>partner.all</li>\n<li>company.all</li>\n<li>partner.company.edit</li>\n<li>company.edit</li>\n</ul>\n\nTags manipulation - both adding and deletion - is performed asynchronously by background task.\nThe result of these operations may be not available immediately after getting a response.",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/MailboxUpdateRequest"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/MailboxesUpdateResponse"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found or page out of range"
          }
        },
        "tags": [
          "Mailboxes"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/mailboxes/{company_id}/user-campaigns-performance/": {
      "get": {
        "operationId": "Get user campaign performance",
        "description": "\nList of a company users performances per campaign\n<br/><b>Scopes:</b>\n<ul>\n<li>partner.all</li>\n<li>company.all</li>\n<li>partner.company.view</li>\n<li>company.view</li>\n</ul>\n",
        "parameters": [
          {
            "name": "period",
            "in": "query",
            "description": "\nPeriod to filter the campaigns by:\n<ul>\n    <li>1 - Last 7 days</li>\n    <li>2 - Last year</li>\n    <li>3 - Last 3 month</li>\n    <li>4 - Last 6 month</li>\n    <li>5 - Custom range (up to 180d) - MM-DD-YYYY - MM-DD-YYYY</li>\n</ul>\n",
            "required": false,
            "type": "integer",
            "enum": [
              1,
              2,
              3,
              4,
              5
            ],
            "default": 3
          },
          {
            "name": "customPeriodFrom",
            "in": "query",
            "description": "Start date of the custom period in MM-DD-YYYY format",
            "required": false,
            "type": "string",
            "format": "date"
          },
          {
            "name": "customPeriodTo",
            "in": "query",
            "description": "End date of the custom period in MM-DD-YYYY format",
            "required": false,
            "type": "string",
            "format": "date"
          },
          {
            "name": "page",
            "in": "query",
            "description": "Page number",
            "required": false,
            "type": "integer",
            "default": 1
          },
          {
            "name": "country",
            "in": "query",
            "description": "Country name to filter the users by",
            "required": false,
            "type": "string",
            "x-nullable": true
          },
          {
            "name": "department",
            "in": "query",
            "description": "Department name to filter the users by",
            "required": false,
            "type": "string",
            "x-nullable": true
          },
          {
            "name": "campaignType",
            "in": "query",
            "description": "\nType of the campaign:\n<ul>\n    <li>1 - Simulation</li>\n    <li>2 - Training</li>\n    <li>3 - Spear Phishing</li>\n</ul>\n",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer",
              "enum": [
                1,
                2,
                3
              ]
            },
            "x-nullable": true,
            "collectionFormat": "multi"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/MailboxesUserPerformanceResponse"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found or page out of range"
          }
        },
        "tags": [
          "Mailboxes"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/mitigation/{company_id}/details/": {
      "post": {
        "operationId": "Get details of mitigations per mailbox",
        "description": "Get details of mitigations per mailbox<br />\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.view</li>\n    <li>company.view</li>\n</ul>\n<b>Period values:</b>\n<ul>\n    <li>0 - Last 24 hours</li>\n    <li>1 - Last 7 days</li>\n    <li>2 - Last 90 days</li>\n    <li>3 - Last 180 days</li>\n    <li>4 - Last 360 days</li>\n    <li>5 - Current year to date</li>\n    <li>6 - All time (Default)</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/IncidentDetailsRequest"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/MitigationPageDetails"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Mitigation"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/mitigation/{company_id}/impersonation/details/": {
      "get": {
        "operationId": "Get the latest company impersonation incidents",
        "description": "Get the latest company impersonation incidents<br/>\nResults are limited to the latest 1000 incidents, a message will appear\ndisplaying if the amount of incidents in the period is over this limit<br/>\n<b>\nPlease note that the IDs returned here are of impersonation attempts,\nnot incidents or reports, so searching these IDs in other endpoints\nwill not return the expected incidents\n</b>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.view</li>\n    <li>company.view</li>\n</ul>\n<br/><b>Period values:</b>\n<ul>\n    <li>0 - Last 24 hours</li>\n    <li>1 - Last 7 days</li>\n    <li>2 - Last 90 days</li>\n    <li>3 - Last 180 days</li>\n    <li>4 - Last 360 days</li>\n    <li>5 - Current year to date</li>\n    <li>6 - All time</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          },
          {
            "name": "period",
            "in": "query",
            "description": "period",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/ImpersonationDetailsPage"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Mitigation"
        ]
      },
      "post": {
        "operationId": "Get the latest company impersonation paginated incidents",
        "description": "Get the latest company impersonation paginated incidents<br/>\n<b>\nPlease note that the IDs returned here are of impersonation attempts,\nnot incidents or reports, so searching these IDs in other endpoints\nwill not return the expected incidents\n</b>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.view</li>\n    <li>company.view</li>\n</ul>\n<b>Period values:</b>\n<ul>\n    <li>0 - Last 24 hours</li>\n    <li>1 - Last 7 days</li>\n    <li>2 - Last 90 days</li>\n    <li>3 - Last 180 days</li>\n    <li>4 - Last 360 days</li>\n    <li>5 - Current year to date</li>\n    <li>6 - All time</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/ImpersonationDetailsRequest"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/ImpersonationDetailsPage"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Mitigation"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/mitigation/{company_id}/incidents/details/": {
      "get": {
        "operationId": "Get a company mitigation details",
        "description": "Get a company mitigation details<br />\n<br/><b>Scopes:</b>\n<ul>\n<li>partner.all</li>\n<li>partner.company.view</li>\n<li>company.view</li>\n</ul>\n<b>Period values:</b>\n<ul>\n    <li>0 - Last 24 hours</li>\n    <li>1 - Last 7 days</li>\n    <li>2 - Last 90 days</li>\n    <li>3 - Last 180 days</li>\n    <li>4 - Last 360 days</li>\n    <li>5 - Current year to date</li>\n    <li>6 - All time</li>\n</ul>",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "required": false,
            "type": "integer",
            "default": 1
          },
          {
            "name": "period",
            "in": "query",
            "required": false,
            "type": "string",
            "default": "6",
            "minLength": 1
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/IncidentPageDetails"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Mitigation"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/mitigation/{company_id}/stats/": {
      "get": {
        "operationId": "Get a company mitigation statistics",
        "description": "Get a company mitigation statistics\n<br/><b>Scopes:</b>\n<ul>\n<li>partner.all</li>\n<li>partner.company.view</li>\n<li>company.view</li>\n</ul>\n<b>Period values:</b>\n<ul>\n<li>0 - Last 24 hours</li>\n<li>1 - Last 7 days</li>\n<li>2 - Last 90 days</li>\n<li>3 - Last 180 days</li>\n<li>4 - Last 360 days</li>\n<li>5 - Current year to date</li>\n<li>6 - All time</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          },
          {
            "name": "period",
            "in": "query",
            "description": "period",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/MitigationStats"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Mitigation"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/mitigation/{company_id}/stats/emails/": {
      "get": {
        "operationId": "Get emails stats",
        "description": "<b>Rate Limit</b>: 20 requests per second<br /><b>Scopes:</b><ul><li>company.view</li></ul>",
        "parameters": [
          {
            "name": "start_time",
            "in": "query",
            "description": "iso-8601 format",
            "required": true,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "end_time",
            "in": "query",
            "description": "iso-8601 format",
            "required": true,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "include_scanback",
            "in": "query",
            "required": false,
            "type": "boolean",
            "default": false
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/EmailsStats"
            }
          },
          "400": {
            "description": "Validation Errors",
            "examples": {
              "application/json": [
                {
                  "end_time": [
                    "This field is required."
                  ],
                  "start_time": [
                    "This field is required."
                  ]
                },
                {
                  "end_time": [
                    "Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]."
                  ],
                  "start_time": [
                    "Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]."
                  ]
                },
                {
                  "end_time": [
                    "The `end_time` must be later than the `start_time`."
                  ]
                },
                {
                  "end_time": [
                    "The time range between `start_time` and `end_time` cannot exceed 365 days."
                  ]
                },
                {
                  "include_scanback": [
                    "Must be a valid boolean."
                  ]
                }
              ]
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Mitigation"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/mitigation/{company_id}/stats/most-targeted-departments/": {
      "get": {
        "operationId": "Most targeted departments",
        "description": "Returns top 5 most targeted departments within requested timeframe<br/>\n<b>Rate Limit</b>: 20 requests per second<br /><b>Scopes:</b><ul><li>company.view</li></ul>",
        "parameters": [
          {
            "name": "start_time",
            "in": "query",
            "description": "iso-8601 format",
            "required": true,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "end_time",
            "in": "query",
            "description": "iso-8601 format",
            "required": true,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "include_scanback",
            "in": "query",
            "required": false,
            "type": "boolean",
            "default": false
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/MostTargetedDepartments"
            }
          },
          "400": {
            "description": "Validation Errors",
            "examples": {
              "application/json": [
                {
                  "end_time": [
                    "This field is required."
                  ],
                  "start_time": [
                    "This field is required."
                  ]
                },
                {
                  "end_time": [
                    "Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]."
                  ],
                  "start_time": [
                    "Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]."
                  ]
                },
                {
                  "end_time": [
                    "The `end_time` must be later than the `start_time`."
                  ]
                },
                {
                  "end_time": [
                    "The time range between `start_time` and `end_time` cannot exceed 365 days."
                  ]
                },
                {
                  "include_scanback": [
                    "Must be a valid boolean."
                  ]
                }
              ]
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Mitigation"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/mitigation/{company_id}/stats/most-targeted-employees/": {
      "get": {
        "operationId": "Most targeted employees",
        "description": "Returns top 5 most targeted employees within requested timeframe<br/>\n<b>Rate Limit</b>: 20 requests per second<br /><b>Scopes:</b><ul><li>company.view</li></ul>",
        "parameters": [
          {
            "name": "start_time",
            "in": "query",
            "description": "iso-8601 format",
            "required": true,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "end_time",
            "in": "query",
            "description": "iso-8601 format",
            "required": true,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "include_scanback",
            "in": "query",
            "required": false,
            "type": "boolean",
            "default": false
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/MostTargetedEmployees"
            }
          },
          "400": {
            "description": "Validation Errors",
            "examples": {
              "application/json": [
                {
                  "end_time": [
                    "This field is required."
                  ],
                  "start_time": [
                    "This field is required."
                  ]
                },
                {
                  "end_time": [
                    "Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]."
                  ],
                  "start_time": [
                    "Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z]."
                  ]
                },
                {
                  "end_time": [
                    "The `end_time` must be later than the `start_time`."
                  ]
                },
                {
                  "end_time": [
                    "The time range between `start_time` and `end_time` cannot exceed 365 days."
                  ]
                },
                {
                  "include_scanback": [
                    "Must be a valid boolean."
                  ]
                }
              ]
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Mitigation"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/mitigation/{company_id}/stats/v2/": {
      "get": {
        "operationId": "Get a company mitigation statistics V2",
        "description": "Get a company mitigation statistics V2\n<br/><b>Scopes:</b>\n<ul>\n<li>partner.all</li>\n<li>partner.company.view</li>\n<li>company.view</li>\n</ul>\n<b>Period values:</b>\n<ul>\n<li>0 - Last 24 hours</li>\n<li>1 - Last 7 days</li>\n<li>2 - Last 90 days</li>\n<li>3 - Last 180 days</li>\n<li>4 - Last 360 days</li>\n<li>5 - Current year to date</li>\n<li>6 - All time</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          },
          {
            "name": "period",
            "in": "query",
            "description": "period",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/MitigationStatsV2View"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Mitigation"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/partner/companies/migrate/": {
      "get": {
        "operationId": "List possible target companies for migration",
        "summary": "List eligible acquiring companies for migration",
        "description": "List companies that can acquire a migrating company. Only returns MSPs under the same parent with active licenses.<b>Scopes:</b><ul><li>partner.partners.view</li></ul>",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "description": "Page number for pagination (starts from 1)",
            "required": false,
            "type": "integer",
            "default": 1,
            "minimum": 1
          },
          {
            "name": "page_size",
            "in": "query",
            "description": "Number of items per page (max 1000)",
            "required": false,
            "type": "integer",
            "default": 100,
            "maximum": 1000,
            "minimum": 1
          },
          {
            "name": "search",
            "in": "query",
            "description": "Search companies by name",
            "required": false,
            "type": "string",
            "maxLength": 100,
            "minLength": 1
          }
        ],
        "responses": {
          "200": {
            "description": "List of possible acquiring companies",
            "schema": {
              "$ref": "#/definitions/PossibleAcquiringCompaniesResponse"
            },
            "examples": {
              "application/json": {
                "total_pages": 2,
                "total_items": 15,
                "page": 1,
                "possible_acquiring_companies": [
                  {
                    "id": 123,
                    "name": "MSP Company A"
                  },
                  {
                    "id": 456,
                    "name": "MSP Company B"
                  }
                ]
              }
            }
          },
          "400": {
            "description": "Bad request - invalid query parameters",
            "examples": {
              "application/json": {
                "page": [
                  "Page number must be 1 or greater"
                ],
                "page_size": [
                  "Page size must be between 1 and 1000"
                ]
              }
            }
          },
          "403": {
            "description": "Forbidden - company does not have required permissions"
          }
        },
        "tags": [
          "Partner"
        ]
      },
      "post": {
        "operationId": "Migrate a Tenant between Partners",
        "summary": "Migrate a Tenant between Partners",
        "description": "Migrate a Tenant from one Partner to another under the same parent. Both Partners must have active licenses and be eligible for migration.<b>Scopes:</b><ul><li>partner.partners.edit</li></ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/PartnerMigrationRequest"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Tenant successfully migrated",
            "schema": {
              "type": "object",
              "properties": {
                "message": {
                  "description": "Success message",
                  "type": "string"
                }
              },
              "example": {
                "message": "Tenant successfully migrated from Partner A to Partner B"
              }
            }
          },
          "400": {
            "description": "Validation error",
            "examples": {
              "application/json": {
                "migrating_company_id": [
                  "Tenant not found.",
                  "Tenant must be managed by a Partner to migrate.",
                  "Cannot migrate a Partner."
                ],
                "non_field_errors": [
                  "Acquiring partner must be different from the current managing partner.",
                  "Cannot migrate sub-company to a higher-level parent using sub-company credentials.",
                  "Migrating partner and acquiring partner must share a common parent.",
                  "Both acquiring and releasing Partners must have active licenses and share the same parent"
                ]
              }
            }
          },
          "403": {
            "description": "Forbidden - company does not have required permissions"
          },
          "500": {
            "description": "Server error - migration failed"
          }
        },
        "tags": [
          "Partner"
        ]
      },
      "parameters": []
    },
    "/partner/create/": {
      "post": {
        "operationId": "Create a new Partner",
        "description": "<b>Scopes:</b><ul><li>partner.all</li><li>partner.partners.create</li></ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/CreatePartner"
            }
          }
        ],
        "responses": {
          "201": {
            "description": "Successful Response",
            "examples": {
              "application/json": {
                "company_id": 1,
                "admin_password": "newpass",
                "app_key": "<api key>"
              }
            }
          },
          "400": {
            "description": "Validation Errors",
            "examples": {
              "application/json": [
                {
                  "ownerEmail": [
                    "Email test@example.com already registered"
                  ]
                },
                {
                  "country": [
                    "\"test\" is not a recognized country name"
                  ]
                },
                {
                  "planType": [
                    "\"2\" is not a valid choice."
                  ]
                }
              ]
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company/Partner was not found"
          }
        },
        "tags": [
          "Partner"
        ]
      },
      "parameters": []
    },
    "/partner/{partner_id}/companies/": {
      "get": {
        "operationId": "List a partner companies and sub partners",
        "description": "List a partner companies and partners\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.partners.view</li>\n</ul>",
        "parameters": [],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/CompanyList"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Partner was not found"
          }
        },
        "tags": [
          "Partner"
        ]
      },
      "parameters": [
        {
          "name": "partner_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/partner/{partner_id}/companies/v2/": {
      "get": {
        "operationId": "List a partner companies and sub partners V2",
        "description": "List a partner companies and partners\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.partners.view</li>\n</ul>",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "description": "Page Number",
            "required": false,
            "type": "integer",
            "default": 1
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/CompanyListV2Response"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Partner was not found"
          }
        },
        "tags": [
          "Partner"
        ]
      },
      "parameters": [
        {
          "name": "partner_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/partner/{partner_id}/features/": {
      "get": {
        "operationId": "Get a Partner features states access",
        "description": "Get a company features States access\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.edit</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/GetPartnerFeature"
            }
          },
          "400": {
            "description": "Missing company id",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Partner"
        ]
      },
      "put": {
        "operationId": "Update a Partner features states access",
        "description": "Update company features States access<br/>\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.company.edit</li>\n</ul>\n<b>Available features:</b>\n<ul>\n    <li>addCompanyOption</li>\n    <li>editMspDashboard</li>\n    <li>enforceMailboxLimit</li>\n    <li>autopilot</li>\n    <li>enableDMARCForPartners</li>\n</ul>\n<b>State:</b> <ul><li>enable</li><li>disable</li></ul>\n<b>Body example</b>\n<br/><p>\n[\n<br>&nbsp;&nbsp;&nbsp;{\n<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\"feature\":\"addCompanyOption\",\n<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\"state\":\"disable\"\n<br>&nbsp;&nbsp;&nbsp;},\n<br>&nbsp;&nbsp;&nbsp;{\n<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\"feature\": \"****\",\n<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\"state\":\"disable\"\n<br>&nbsp;&nbsp;&nbsp;}\n<br>]\n</p>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/UpdatePartnerFeature"
              }
            }
          },
          "400": {
            "description": "Missing company id or wrong request",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Partner"
        ]
      },
      "parameters": [
        {
          "name": "partner_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/partner/{partner_id}/plans/": {
      "get": {
        "operationId": "List plans of a partner companies",
        "description": "List a partner companies Licenses\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.license.view</li>\n</ul>",
        "parameters": [
          {
            "name": "partner_id",
            "in": "path",
            "description": "partner id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/PlansDetails"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Partner was not found"
          }
        },
        "tags": [
          "Partner"
        ]
      },
      "parameters": [
        {
          "name": "partner_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/partner/{partner_id}/usage-report-monthly/": {
      "post": {
        "operationId": "Partner Company Usage Report Monthly",
        "description": "<b>Scopes:</b>\n<ul>\n    <li>partner.license.view</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/PartnerCompanyUsageReportMonthlyRequest"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/PartnerCompanyUsageReportMonthlyResponse"
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "No company were found that matching the query"
          }
        },
        "tags": [
          "Partner"
        ]
      },
      "parameters": [
        {
          "name": "partner_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/plans-details/domains/{company_id}/": {
      "get": {
        "operationId": "Get a company Licensed Domains PD",
        "description": "Get a company's \"Licensed Domains\"\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "examples": {
              "application/json": {
                "company_id": 1,
                "licensed_domains": [
                  "example.com"
                ]
              }
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Plans Details"
        ]
      },
      "put": {
        "operationId": "Add new Licensed Domains to a company PD",
        "description": "Add new \"Licensed Domains\" to a company\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/AllowedDomains"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "examples": {
              "application/json": {
                "company_id": 1,
                "domains_added": [
                  "additional.com"
                ],
                "existing_domains": [
                  "example.com"
                ]
              }
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Plans Details"
        ]
      },
      "delete": {
        "operationId": "Delete Licensed Domains from a company PD",
        "description": "Delete \"Licensed Domains\" from a company\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/AllowedDomains"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "examples": {
              "application/json": {
                "company_id": 1,
                "deleted_domains": [
                  "removed.com"
                ]
              }
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Plans Details"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/plans-details/{company_id}": {
      "get": {
        "operationId": "Get a company license",
        "description": "Get company license\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.license.view</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/PlanDetails"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Plans Details"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/plans/domains-stats/{company_id}/": {
      "get": {
        "operationId": "Get domain-based mailbox statistics",
        "description": "\nStatistics of mailboxes grouped by domain for a company\n<br/><b>Scopes:</b>\n<ul>\n<li>company.all</li>\n<li>company.view</li>\n</ul>\n",
        "parameters": [],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "domain": {
                    "description": "Domain name",
                    "type": "string"
                  },
                  "active_mailboxes": {
                    "description": "Number of active mailboxes for this domain",
                    "type": "integer"
                  },
                  "total_mailboxes": {
                    "description": "Total number of mailboxes for this domain",
                    "type": "integer"
                  }
                }
              }
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Domains"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/plans/domains/{company_id}/": {
      "get": {
        "operationId": "Get a company Licensed Domains",
        "description": "Get a company's \"Licensed Domains\"\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "examples": {
              "application/json": {
                "company_id": 1,
                "licensed_domains": [
                  "example.com"
                ]
              }
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Plans"
        ]
      },
      "put": {
        "operationId": "Add new Licensed Domains to a company",
        "description": "Add new \"Licensed Domains\" to a company\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/AllowedDomains"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "examples": {
              "application/json": {
                "company_id": 1,
                "domains_added": [
                  "additional.com"
                ],
                "existing_domains": [
                  "example.com"
                ]
              }
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Plans"
        ]
      },
      "delete": {
        "operationId": "Delete Licensed Domains from a company",
        "description": "Delete \"Licensed Domains\" from a company\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n    <li>company.view</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/AllowedDomains"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "examples": {
              "application/json": {
                "company_id": 1,
                "deleted_domains": [
                  "removed.com"
                ]
              }
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Plans"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/plans/{company_id}": {
      "get": {
        "operationId": "Get a company license plan",
        "description": "Get company license plan\n<br/><b>Scopes:</b>\n<ul>\n    <li>partner.all</li>\n    <li>partner.license.view</li>\n</ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/PlanDetails"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Plans"
        ]
      },
      "post": {
        "operationId": "Update a company license",
        "description": "Update company license\n<br/><br/><b>Scopes:</b><ul><li>partner.all</li></ul>\n<b>Licenses:</b>\n<ul>\n<li>7 - SAT Suite</li>\n<li>2 - Starter</li>\n<li>3 - Core</li>\n<li>4 - Email Protect</li>\n<li>5 - Complete Protect</li>\n<li>6 - Ironscales Protect</li>\n</ul>\n<b>Trial Licenses:</b>\n<ul>\n<li>3 - Core</li>\n<li>4 - Email Protect</li>\n<li>5 - Complete Protect</li>\n<li>6 - Ironscales Protect</li>\n<li>7 - SAT Suite</li>\n</ul>\n<b>IronSchools Premium types Values:</b>\n<ul>\n<li>1 - NINJIO</li>\n<li>3 - Habitu8</li>\n<li>4 - Cybermaniacs Videos</li>\n</ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/PlanSetOrUpdate"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/PlanDetails"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Plans"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/plans/{company_id}/cancel/": {
      "post": {
        "operationId": "Cancel a company licenses",
        "description": "Cancel company licenses\n<br/><b>Scopes:</b>\n<ul><li>partner.all</li><li>partner.license.edit</li></ul>\n<b>Licenses:</b>\n<ul>\n<li>plan-license</li>\n<li>trial-license</li>\n<li>premium-content</li>\n</ul>\n<b>Body example:</b>\n<br><p>{\"licenses\": [\"plan-license\"]}</p>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/CancelPlan"
            }
          },
          {
            "name": "company_id",
            "in": "path",
            "description": "company id",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "schema": {
              "$ref": "#/definitions/PlanDetails"
            }
          },
          "400": {
            "description": "Error explanation in error_message",
            "examples": {
              "application/json": {
                "error_message": "explanation"
              }
            }
          },
          "403": {
            "description": "No permissions"
          },
          "404": {
            "description": "Company was not found"
          }
        },
        "tags": [
          "Plans"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/sat/{company_id}/campaigns/": {
      "get": {
        "operationId": "Get Campaigns List",
        "description": "<b>Scopes:</b><ul><li>company.view</li><li>partner.company.view</li></ul>",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "description": "Page number (default: 1)",
            "required": false,
            "type": "integer",
            "default": 1,
            "minimum": 1
          },
          {
            "name": "page_size",
            "in": "query",
            "description": "Number of items per page (default: 25, max: 50)",
            "required": false,
            "type": "integer",
            "default": 25,
            "maximum": 50,
            "minimum": 1
          },
          {
            "name": "search",
            "in": "query",
            "description": "Case-insensitive substring filter for campaign names.\n- Example: 'training' matches 'Security Training'",
            "required": false,
            "type": "string",
            "minLength": 1
          },
          {
            "name": "flow_types",
            "in": "query",
            "description": "Filter by campaign flow type IDs.\n- `1` = Training Only - Filter for campaigns that only include training content\n- `2` = Simulation and Training - Filter for campaigns that include both phishing simulation and training\n",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer",
              "enum": [
                1,
                2,
                3
              ]
            }
          },
          {
            "name": "locale_ids",
            "in": "query",
            "description": "Filter by locale IDs.\n- Use numeric identifiers from the locale catalog",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          {
            "name": "statuses",
            "in": "query",
            "description": "Filter by campaign status codes.\n- `0` = Draft - Filter for campaigns in draft state\n- `1` = Collecting (Active) - Filter for campaigns actively collecting participant data\n- `2` = Completed - Filter for campaigns that have finished\n- `3` = Pending - Filter for campaigns approved but waiting to start\n- `4` = Active - Filter for campaigns currently running\n- `5` = Inactive - Filter for inactive campaigns",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer",
              "enum": [
                0,
                1,
                2,
                3,
                4,
                5
              ]
            }
          },
          {
            "name": "scheduled_date_from",
            "in": "query",
            "description": "Earliest campaign schedule date (inclusive).\n- Format: MM-DD-YYYY\n- Cannot be combined with `scheduled_time_from` / `scheduled_time_to`.",
            "required": false,
            "type": "string",
            "format": "date"
          },
          {
            "name": "scheduled_date_to",
            "in": "query",
            "description": "Latest campaign schedule date (inclusive).\n- Format: MM-DD-YYYY\n- Cannot be combined with `scheduled_time_from` / `scheduled_time_to`.",
            "required": false,
            "type": "string",
            "format": "date"
          },
          {
            "name": "scheduled_time_from",
            "in": "query",
            "description": "Earliest campaign schedule timestamp (inclusive).\n- Format: ISO 8601 datetime (e.g., `2026-03-01T00:00:00Z`)\n- Cannot be combined with `scheduled_date_from` / `scheduled_date_to`.",
            "required": false,
            "type": "string",
            "format": "date-time"
          },
          {
            "name": "scheduled_time_to",
            "in": "query",
            "description": "Latest campaign schedule timestamp (inclusive).\n- Format: ISO 8601 datetime (e.g., `2026-03-31T23:59:59Z`)\n- Cannot be combined with `scheduled_date_from` / `scheduled_date_to`.",
            "required": false,
            "type": "string",
            "format": "date-time"
          }
        ],
        "responses": {
          "200": {
            "description": "",
            "schema": {
              "$ref": "#/definitions/CampaignListResponse"
            }
          },
          "400": {
            "description": "Bad Request - Invalid request parameters or validation error",
            "examples": {
              "application/json": {
                "field_name": [
                  "Field related error message."
                ]
              }
            }
          },
          "401": {
            "description": "Unauthorized - Authentication credentials were not provided or are invalid",
            "examples": {
              "application/json": {
                "detail": "Authentication credentials were not provided."
              }
            }
          },
          "403": {
            "description": "Forbidden - You do not have permission to perform this action",
            "examples": {
              "application/json": {
                "detail": "You do not have permission for company 123"
              }
            }
          },
          "404": {
            "description": "Not Found - The requested resource was not found",
            "examples": {
              "application/json": {
                "detail": "Not found."
              }
            }
          },
          "429": {
            "description": "Too Many Requests - Rate limit exceeded",
            "examples": {
              "application/json": {
                "detail": "Request was throttled. Expected available in 60 seconds."
              }
            }
          },
          "500": {
            "description": "Internal Server Error - An unexpected error occurred",
            "examples": {
              "application/json": {
                "detail": "Internal server error."
              }
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "post": {
        "operationId": "Create Draft Campaign",
        "summary": "Create a new draft campaign.",
        "description": "Creates a new campaign in DRAFT status. The campaign can be configured\nwith various settings including participants, scenarios, trainings,\nnotifications, and campaign-specific data based on the flow type.<b>Scopes:</b><ul><li>company.edit</li><li>partner.company.edit</li></ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/CampaignCreateRequest"
            }
          }
        ],
        "responses": {
          "201": {
            "description": "Campaign successfully created",
            "schema": {
              "$ref": "#/definitions/CampaignCreateResponse"
            },
            "examples": {
              "application/json": {
                "id": 123
              }
            }
          },
          "400": {
            "description": "Bad Request - Invalid request parameters or validation error",
            "examples": {
              "application/json": {
                "field_name": [
                  "Field related error message."
                ]
              }
            }
          },
          "401": {
            "description": "Unauthorized - Authentication credentials were not provided or are invalid",
            "examples": {
              "application/json": {
                "detail": "Authentication credentials were not provided."
              }
            }
          },
          "403": {
            "description": "Forbidden - You do not have permission to perform this action",
            "examples": {
              "application/json": {
                "detail": "You do not have permission for company 123"
              }
            }
          },
          "404": {
            "description": "Not Found - The requested resource was not found",
            "examples": {
              "application/json": {
                "detail": "Not found."
              }
            }
          },
          "429": {
            "description": "Too Many Requests - Rate limit exceeded",
            "examples": {
              "application/json": {
                "detail": "Request was throttled. Expected available in 60 seconds."
              }
            }
          },
          "500": {
            "description": "Internal Server Error - An unexpected error occurred",
            "examples": {
              "application/json": {
                "detail": "Internal server error."
              }
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/sat/{company_id}/campaigns/{campaign_id}/": {
      "get": {
        "operationId": "Get Campaign Details",
        "description": "<b>Scopes:</b><ul><li>company.view</li><li>partner.company.view</li></ul>",
        "parameters": [],
        "responses": {
          "200": {
            "description": "",
            "schema": {
              "$ref": "#/definitions/CampaignDetailsResponse"
            }
          },
          "401": {
            "description": "Unauthorized - Authentication credentials were not provided or are invalid",
            "examples": {
              "application/json": {
                "detail": "Authentication credentials were not provided."
              }
            }
          },
          "403": {
            "description": "Forbidden - You do not have permission to perform this action",
            "examples": {
              "application/json": {
                "detail": "You do not have permission for company 123"
              }
            }
          },
          "404": {
            "description": "Not Found - The requested resource was not found",
            "examples": {
              "application/json": {
                "detail": "Not found."
              }
            }
          },
          "429": {
            "description": "Too Many Requests - Rate limit exceeded",
            "examples": {
              "application/json": {
                "detail": "Request was throttled. Expected available in 60 seconds."
              }
            }
          },
          "500": {
            "description": "Internal Server Error - An unexpected error occurred",
            "examples": {
              "application/json": {
                "detail": "Internal server error."
              }
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "delete": {
        "operationId": "Delete Campaign",
        "description": "Delete a campaign.<b>Scopes:</b><ul><li>company.edit</li><li>partner.company.edit</li></ul>",
        "parameters": [],
        "responses": {
          "204": {
            "description": "No Content - Campaign successfully deleted"
          },
          "401": {
            "description": "Unauthorized - Authentication credentials were not provided or are invalid",
            "examples": {
              "application/json": {
                "detail": "Authentication credentials were not provided."
              }
            }
          },
          "403": {
            "description": "Forbidden - You do not have permission to perform this action",
            "examples": {
              "application/json": {
                "detail": "You do not have permission for company 123"
              }
            }
          },
          "404": {
            "description": "Not Found - The requested resource was not found",
            "examples": {
              "application/json": {
                "detail": "Not found."
              }
            }
          },
          "429": {
            "description": "Too Many Requests - Rate limit exceeded",
            "examples": {
              "application/json": {
                "detail": "Request was throttled. Expected available in 60 seconds."
              }
            }
          },
          "500": {
            "description": "Internal Server Error - An unexpected error occurred",
            "examples": {
              "application/json": {
                "detail": "Internal server error."
              }
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        },
        {
          "name": "campaign_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/sat/{company_id}/campaigns/{campaign_id}/approve/": {
      "post": {
        "operationId": "Approve Campaign",
        "summary": "Approve a draft campaign.",
        "description": "Approves a campaign in DRAFT or PENDING status, making it ready for execution.\nThe campaign must pass various validation checks including license validation,\nparticipant count validation, and scenario/training validation based on flow type.<b>Scopes:</b><ul><li>company.edit</li><li>partner.company.edit</li></ul>",
        "parameters": [],
        "responses": {
          "200": {
            "description": "OK - Campaign successfully approved"
          },
          "400": {
            "description": "Bad Request - Invalid request parameters or validation error",
            "examples": {
              "application/json": {
                "field_name": [
                  "Field related error message."
                ]
              }
            }
          },
          "401": {
            "description": "Unauthorized - Authentication credentials were not provided or are invalid",
            "examples": {
              "application/json": {
                "detail": "Authentication credentials were not provided."
              }
            }
          },
          "403": {
            "description": "Forbidden - You do not have permission to perform this action",
            "examples": {
              "application/json": {
                "detail": "You do not have permission for company 123"
              }
            }
          },
          "404": {
            "description": "Not Found - The requested resource was not found",
            "examples": {
              "application/json": {
                "detail": "Not found."
              }
            }
          },
          "429": {
            "description": "Too Many Requests - Rate limit exceeded",
            "examples": {
              "application/json": {
                "detail": "Request was throttled. Expected available in 60 seconds."
              }
            }
          },
          "500": {
            "description": "Internal Server Error - An unexpected error occurred",
            "examples": {
              "application/json": {
                "detail": "Internal server error."
              }
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        },
        {
          "name": "campaign_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/sat/{company_id}/campaigns/{campaign_id}/stop/": {
      "post": {
        "operationId": "Stop Campaign",
        "summary": "Stop an active campaign.",
        "description": "Stops an active campaign by stopping email sending and event tracking.<b>Scopes:</b><ul><li>company.edit</li><li>partner.company.edit</li></ul>",
        "parameters": [],
        "responses": {
          "200": {
            "description": "OK - Campaign successfully stopped"
          },
          "400": {
            "description": "Bad Request - Invalid request parameters or validation error",
            "examples": {
              "application/json": {
                "field_name": [
                  "Field related error message."
                ]
              }
            }
          },
          "401": {
            "description": "Unauthorized - Authentication credentials were not provided or are invalid",
            "examples": {
              "application/json": {
                "detail": "Authentication credentials were not provided."
              }
            }
          },
          "403": {
            "description": "Forbidden - You do not have permission to perform this action",
            "examples": {
              "application/json": {
                "detail": "You do not have permission for company 123"
              }
            }
          },
          "404": {
            "description": "Not Found - The requested resource was not found",
            "examples": {
              "application/json": {
                "detail": "Not found."
              }
            }
          },
          "429": {
            "description": "Too Many Requests - Rate limit exceeded",
            "examples": {
              "application/json": {
                "detail": "Request was throttled. Expected available in 60 seconds."
              }
            }
          },
          "500": {
            "description": "Internal Server Error - An unexpected error occurred",
            "examples": {
              "application/json": {
                "detail": "Internal server error."
              }
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        },
        {
          "name": "campaign_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/sat/{company_id}/cta/": {
      "get": {
        "operationId": "Get call for action pages",
        "description": "<p>Retrieve a paginated list of call for action pages available for the specified company. The endpoint returns system pages, public pages, company-owned pages, and brand owner pages (if the company is part of a brand). Results can be filtered by search term. </p><b>Scopes:</b><ul><li>company.view</li><li>partner.company.view</li></ul>",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "description": "Page number for pagination (default: 1)",
            "required": false,
            "type": "integer",
            "default": 1,
            "minimum": 1
          },
          {
            "name": "page_size",
            "in": "query",
            "description": "Number of items per page (default: 25, max: 50)",
            "required": false,
            "type": "integer",
            "default": 25,
            "maximum": 50,
            "minimum": 1
          },
          {
            "name": "search",
            "in": "query",
            "description": "Search term to filter call for action pages by name",
            "required": false,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "Successfully retrieved call for action pages",
            "schema": {
              "$ref": "#/definitions/CallForAction"
            },
            "examples": {
              "application/json": {
                "page": 1,
                "total_pages": 2,
                "total_count": 35,
                "data": [
                  {
                    "id": 1,
                    "name": "Example Call for Action",
                    "page_title": "Example Title",
                    "content": "<html><form>...</form></html>",
                    "is_system": true,
                    "is_public": true,
                    "last_updated": "2023-01-16T09:45:32.051421Z",
                    "tags": "System",
                    "company_id": null
                  }
                ]
              }
            }
          },
          "400": {
            "description": "Bad Request - Invalid request parameters or validation error",
            "examples": {
              "application/json": {
                "field_name": [
                  "Field related error message."
                ]
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/sat/{company_id}/landing-pages/": {
      "get": {
        "operationId": "Get landing pages",
        "summary": "Get landing pages for a company.",
        "description": "Returns a paginated list of landing pages that are available\nfor the specified company. This includes:\n- System landing pages\n- Company-owned landing pages\n- Brand owner's landing pages (if company is part of a brand)<b>Scopes:</b><ul><li>company.view</li><li>partner.company.view</li></ul>",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "required": false,
            "type": "integer",
            "default": 1,
            "minimum": 1
          },
          {
            "name": "page_size",
            "in": "query",
            "required": false,
            "type": "integer",
            "default": 25,
            "maximum": 50,
            "minimum": 1
          },
          {
            "name": "locale_ids",
            "in": "query",
            "description": "Filter by locale IDs.\n- Use numeric identifiers from the locale catalog\n- If not provided, company's selected locales will be used",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          {
            "name": "search",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "created_by",
            "in": "query",
            "description": "Filter by created by codes.\n- `1` = System\n- `2` = Company\n- `3` = MSP\n- Provide one or both codes",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer",
              "enum": [
                1,
                2,
                3
              ]
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successfully Response",
            "schema": {
              "$ref": "#/definitions/LandingPages"
            }
          },
          "400": {
            "description": "Bad Request - Invalid request parameters or validation error",
            "examples": {
              "application/json": {
                "field_name": [
                  "Field related error message."
                ]
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/sat/{company_id}/participants/": {
      "get": {
        "operationId": "Get Participants List",
        "summary": "Get list of campaign participants grouped by categories.",
        "description": "Returns participants data organized by departments, cities, countries,\ntitles, tags, featured groups, segments, and awareness levels.<b>Scopes:</b><ul><li>company.view</li><li>partner.company.view</li></ul>",
        "parameters": [],
        "responses": {
          "200": {
            "description": "Successful response containing participants data organized by categories (departments, cities, countries, etc.) with participant counts.",
            "schema": {
              "$ref": "#/definitions/ParticipantsListResponse"
            },
            "examples": {
              "application/json": {
                "all_company": 150,
                "names": {
                  "john.doe@example.com": {
                    "full_name": "John Doe",
                    "mail": "john.doe@example.com"
                  },
                  "jane.smith@example.com": {
                    "full_name": "Jane Smith",
                    "mail": "jane.smith@example.com"
                  }
                },
                "departments": {
                  "Engineering": 45,
                  "Sales": 30,
                  "Marketing": 25,
                  "HR": 20,
                  "Finance": 15,
                  "Operations": 15
                },
                "cities": {
                  "New York": 60,
                  "San Francisco": 40,
                  "London": 30,
                  "Tel Aviv": 20
                },
                "countries": {
                  "United States": 100,
                  "United Kingdom": 30,
                  "Israel": 20
                },
                "titles": {
                  "Software Engineer": 25,
                  "Sales Manager": 15,
                  "Marketing Director": 10,
                  "HR Manager": 8
                },
                "tags": {
                  "Executive": 5,
                  "Remote": 50,
                  "On-site": 100
                },
                "featured_groups": {
                  "All Executives": 5,
                  "All Managers": 20
                },
                "segments": {
                  "High Risk Users": 10,
                  "New Employees": 15
                },
                "awareness_levels": {
                  "Beginner Level": 30,
                  "Mid Level": 80,
                  "Expert Level": 40
                }
              }
            }
          },
          "400": {
            "description": "Bad Request - Invalid request parameters or validation error",
            "examples": {
              "application/json": {
                "field_name": [
                  "Field related error message."
                ]
              }
            }
          },
          "401": {
            "description": "Unauthorized - Authentication credentials were not provided or are invalid",
            "examples": {
              "application/json": {
                "detail": "Authentication credentials were not provided."
              }
            }
          },
          "403": {
            "description": "Forbidden - You do not have permission to perform this action",
            "examples": {
              "application/json": {
                "detail": "You do not have permission for company 123"
              }
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too Many Requests - Rate limit exceeded",
            "examples": {
              "application/json": {
                "detail": "Request was throttled. Expected available in 60 seconds."
              }
            }
          },
          "500": {
            "description": "Internal Server Error - An unexpected error occurred",
            "examples": {
              "application/json": {
                "detail": "Internal server error."
              }
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "post": {
        "operationId": "Calculate Participants",
        "summary": "Calculate participants based on include/exclude filters.",
        "description": "Returns a list of participant candidates matching the specified\ninclude and exclude criteria, along with metadata including total count,\nlocale IDs, and awareness levels distribution.<b>Scopes:</b><ul><li>company.edit</li><li>partner.company.edit</li></ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/ParticipantsCalculateRequest"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful response containing calculated participants with metadata.",
            "schema": {
              "$ref": "#/definitions/ParticipantsCalculateResponse"
            },
            "examples": {
              "application/json": {
                "meta": {
                  "count": 150,
                  "locale_ids": [
                    1,
                    2,
                    3
                  ],
                  "awareness_levels": {
                    "beginner": 30,
                    "mid": 80,
                    "expert": 40
                  }
                },
                "items": [
                  {
                    "id": 1,
                    "first_name": "John",
                    "last_name": "Doe",
                    "email": "john.doe@example.com"
                  },
                  {
                    "id": 2,
                    "first_name": "Jane",
                    "last_name": "Smith",
                    "email": "jane.smith@example.com"
                  }
                ]
              }
            }
          },
          "400": {
            "description": "Bad Request - Invalid request parameters or validation error",
            "examples": {
              "application/json": {
                "field_name": [
                  "Field related error message."
                ]
              }
            }
          },
          "401": {
            "description": "Unauthorized - Authentication credentials were not provided or are invalid",
            "examples": {
              "application/json": {
                "detail": "Authentication credentials were not provided."
              }
            }
          },
          "403": {
            "description": "Forbidden - You do not have permission to perform this action",
            "examples": {
              "application/json": {
                "detail": "You do not have permission for company 123"
              }
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too Many Requests - Rate limit exceeded",
            "examples": {
              "application/json": {
                "detail": "Request was throttled. Expected available in 60 seconds."
              }
            }
          },
          "500": {
            "description": "Internal Server Error - An unexpected error occurred",
            "examples": {
              "application/json": {
                "detail": "Internal server error."
              }
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/sat/{company_id}/participants/search/": {
      "post": {
        "operationId": "Search Participants",
        "summary": "Search for campaign participants.",
        "description": "Returns a flattened list of matching items based on the search query.<b>Scopes:</b><ul><li>company.view</li><li>partner.company.view</li></ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/ParticipantsSearchRequest"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful response containing flattened list of matching participant items.",
            "schema": {
              "$ref": "#/definitions/ParticipantsSearchResponse"
            },
            "examples": {
              "application/json": {
                "items": [
                  {
                    "name": "Engineering",
                    "tag": "Departments"
                  },
                  {
                    "name": "John Doe",
                    "tag": "Names",
                    "mail": "john.doe@example.com"
                  },
                  {
                    "name": "New York",
                    "tag": "Cities"
                  }
                ]
              }
            }
          },
          "400": {
            "description": "Bad Request - Invalid request parameters or validation error",
            "examples": {
              "application/json": {
                "field_name": [
                  "Field related error message."
                ]
              }
            }
          },
          "401": {
            "description": "Unauthorized - Authentication credentials were not provided or are invalid",
            "examples": {
              "application/json": {
                "detail": "Authentication credentials were not provided."
              }
            }
          },
          "403": {
            "description": "Forbidden - You do not have permission to perform this action",
            "examples": {
              "application/json": {
                "detail": "You do not have permission for company 123"
              }
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too Many Requests - Rate limit exceeded",
            "examples": {
              "application/json": {
                "detail": "Request was throttled. Expected available in 60 seconds."
              }
            }
          },
          "500": {
            "description": "Internal Server Error - An unexpected error occurred",
            "examples": {
              "application/json": {
                "detail": "Internal server error."
              }
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/sat/{company_id}/setup/": {
      "get": {
        "operationId": "Get Campaign Setup",
        "description": "\nRetrieve campaign setup and settings data for the specified company.\nThis endpoint provides configuration data needed for campaign creation and management,\nincluding license limits, training content vendors, default content templates, and company settings.\n<b>Scopes:</b><ul><li>company.view</li><li>partner.company.view</li></ul>",
        "parameters": [
          {
            "name": "company_id",
            "in": "path",
            "description": "Company ID",
            "required": true,
            "type": "integer"
          }
        ],
        "responses": {
          "200": {
            "description": "Successful response containing campaign setup data",
            "schema": {
              "$ref": "#/definitions/CampaignSetup"
            },
            "examples": {
              "application/json": {
                "languages": [
                  {
                    "id": 1,
                    "name": "English",
                    "short_name": "En",
                    "localized_name": "English",
                    "ltr": true,
                    "enabled": true,
                    "default": true
                  },
                  {
                    "id": 2,
                    "name": "Hebrew",
                    "short_name": "He",
                    "localized_name": "עברית",
                    "ltr": false,
                    "enabled": true,
                    "default": false
                  }
                ],
                "timezone": "Asia/Jerusalem",
                "workdays": 1,
                "campaigns_limit_for_year": null,
                "campaign_mails_limit": null,
                "allowed_senders_for_training_campaigns": [
                  "ironscales Security Team (IRONSCALES) <training@ironscales.com>"
                ],
                "manager_notification_state": 3,
                "default_training_reminder_content_simulation": {
                  "en": {
                    "body": "\n<p>\n    Hi {first_name},\n</p>\n\n<p>\n    You recently fell for a simulated phishing attack. \n    To give you the tools to recognize malicious emails in the future, \n    please watch the Phishing Awareness Training video.\n<p/>\n\n<p>\n    Please click the link below to start the training. It will only take a few minutes.\n    <br/>\n    {training_page_url}\n<p/>\n\n<p>\n    Thank you,\n    <br/>\n    The {company_name} Security Team\n</p>\n",
                    "subject": "Complete your anti-phishing training today"
                  },
                  "he": {
                    "body": "\n<div dir=\"rtl\">    \n<p>\n   שלום {first_name},\n</p>\n\n<p>\n    לאחרונה נפלת להתקפת דיוג (פישינג) מדומה. על מנת לתת לך את הכלים לזהות הודעות דו\"ל זדוניות בעתיד, אנא צפה בלומדת אבטחת המידע המצורפת.\n<p/>\n\n<p>\nאנא לחץ על הקישור להלן כדי להתחיל את הלימודה. זה ייקח רק מספר דקות.\n    <br/>\n    {training_page_url}\n<p/>\n\n<p>\n    בברכה,\n    <br/>\n   צוות אבטחת המידע {company_name}.\n</p>\n</div>\n",
                    "subject": "השלם/י את לומדת אבטחת המידע היום"
                  }
                },
                "default_training_reminder_content_training": {
                  "en": {
                    "body": "\n<div style=\"font-size: 16px; margin-bottom: 25px;\">\n    Hi <b>{{ first_name }}</b>,\n</div>\n<div style=\"max-width: 445px; margin-bottom: 28px;\">\n    <div>\n        This is a friendly reminder that you haven't completed your Security Awareness Training yet.\n    </div>\n    <div>\n        Please complete the training by clicking the video below. It will only take a few minutes.\n    </div>\n</div>",
                    "subject": "Security Awareness Training: {{ module_title }}"
                  },
                  "he": {
                    "body": "\n<div style=\"font-size: 16px; margin-bottom: 25px;\">\n    ,<b>{{ first_name }}</b> שלום\n</div>\n<div style=\"max-width: 445px; margin-bottom: 28px;\">\n    <div>\n        .זוהי תזכורת על כך שעדיין לא השלמת הדרכה בנושא מודעות לאבטחה\n    </div>\n    <div>\n        .נא להשלים את ההדרכה על-ידי לחיצה על הסרטון למטה. זה ייקח רק מספר דקות\n    </div>\n</div>",
                    "subject": "הדרכה בנושא מודעות לאבטחה {{ module_title }}"
                  }
                },
                "default_campaign_failed_alert_content": {
                  "en": {
                    "body": "<p>Dear {first_name}</p>\n\n<p>In our ongoing effort to prevent email phishing at {company_name}, we have launched an anti-phishing campaign.</p>\n\n<p>Unfortunately, you fell for a phishing attempt and did not pass the test. Please take a few minutes to watch the training video linked: {training_page_url}</p>\n\n<p>Thank you for your participation,<br />\n{company_name}</p>\n\n<p>Security Team</p>",
                    "subject": "Action Required - Complete Your anti-phishing Training"
                  },
                  "he": {
                    "body": "\n<div dir=\"rtl\">\n<p>\n    שלום {first_name},\n</p>\n\n<p>\nבמאמץ המתמשך למנוע התקפות פישינג ב {company_name}, ביצענו תרגיל אבטחת מידע.\n</p>\n\n<p>\nלצערנו נפלת בתרגיל ולכן עליך לצפות בלומדה בנושא אבטחת מידע. אנא לחץ על הקישור:  {training_page_url}\n</p>\n\n<p>\nתודה על השתתפותך,\n<br />{company_name}\n</p>\n\n<p>\nצוות אבטחת המידע\n</p>\n</div>\n",
                    "subject": "השלם את הלומדה בנושא אבטחת מידע"
                  }
                },
                "default_manager_notification_banner_content": {
                  "en": {
                    "text": "\nYour manager, {manager_full_name}, will be notified that you have not yet completed the mandatory training.\nPlease complete it as soon as possible\n"
                  },
                  "he": {
                    "text": "\nהמנהל שלך,{manager_full_name}, יקבל התראה שעדיין לא השלמת את הציפייה בלומדת החובה. אנא השלם זאת בהקדם האפשרי.\n"
                  }
                },
                "default_manager_report_email_content": {
                  "en": {
                    "body": "\nDear {first_name},\n\nAs part of the \"{campaign_name}\" campaign, we wanted to notify you that some employees on your team have not yet completed their mandatory training, despite receiving {reminders_count} or more automated reminders.\nThese employees have been informed that their incomplete status has been shared with you.\nWe have attached a file with the details of the employees who have not finished their assigned training.\nPlease review the attached file for more information.\n\nBest regards,\n{company_name}\n",
                    "subject": "Employees with Incomplete Training for \"{campaign_name}\""
                  },
                  "he": {
                    "body": "\nשלום {first_name},\n\nכחלק מקמפיין \"{campaign_name}\", ברצוננו ליידע אותך כי יש עובדים בצוות שלך שעדיין לא השלימו את הציפייה בלומדת החובה, על אף שקיבלו {reminders_count} תזכורות אוטומטיות.\nעובדים אלה קיבלו הודעה כי הינך מיודע על כך שהם לא השלימו את הציפייה בלומדת.\n\nמצורף למייל זה קובץ המכיל את כל פרטי העובדים שטרם השלימו את הלומדת.\n\nבברכה,\n{company_name}\n",
                    "subject": "עובדים שטרם השלימו את הציפייה בלומדת עבור קמפיין  -  \"{campaign_name}\""
                  }
                }
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/sat/{company_id}/templates/": {
      "get": {
        "operationId": "Get Templates List",
        "summary": "Get templates list.",
        "description": "Returns a paginated list of mail templates filtered by various criteria\nincluding locale, creator, type, level, category, and search term.<b>Scopes:</b><ul><li>company.view</li><li>partner.company.view</li></ul>",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "required": false,
            "type": "integer",
            "default": 1,
            "minimum": 1
          },
          {
            "name": "page_size",
            "in": "query",
            "required": false,
            "type": "integer",
            "default": 25,
            "maximum": 50,
            "minimum": 1
          },
          {
            "name": "created_by",
            "in": "query",
            "description": "Filter by template creator codes.\n- `1` = System - Templates provided by the system\n- `2` = Company - Templates owned by the current company\n- `3` = MSP - Templates provided by the MSP\n- `4` = Community - Community-contributed templates\n- Provide one or more codes",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer",
              "enum": [
                1,
                2,
                3,
                4
              ]
            }
          },
          {
            "name": "locale_ids",
            "in": "query",
            "description": "Filter by locale IDs.\n- Use numeric identifiers from the locale catalog\n- If not provided, company's selected locales will be used",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          {
            "name": "type",
            "in": "query",
            "description": "Filter by template type codes.\n- `0` = Drive-by (links)\n- `1` = Attachment\n- `2` = Call for Action",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer",
              "enum": [
                0,
                1,
                2
              ]
            }
          },
          {
            "name": "search",
            "in": "query",
            "required": false,
            "type": "string"
          },
          {
            "name": "category_ids",
            "in": "query",
            "description": "Filter by template category (scenario group) IDs. - Use endpoint /appapi/sat/{company_id}/templates/categories/ to get the list of available categories",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          {
            "name": "level",
            "in": "query",
            "description": "Array of integers\nFilter by template level (difficulty) codes.\n- `0` = Beginner\n- `1` = Intermediate\n- `2` = Advanced",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer",
              "enum": [
                0,
                1,
                2
              ]
            }
          },
          {
            "name": "sort",
            "in": "query",
            "description": "Field to sort templates by:\n- `last_updated` - Sort by last updated date\n- `name` - Sort by template name\n- `avg_click_rate` - Sort by average click rate (per selected locales)\n- `avg_reported_rate` - Sort by average reported rate (per selected locales)",
            "required": false,
            "type": "string",
            "enum": [
              "last_updated",
              "name",
              "avg_click_rate",
              "avg_reported_rate"
            ]
          },
          {
            "name": "order",
            "in": "query",
            "description": "Sort order: `asc` for ascending, `desc` for descending",
            "required": false,
            "type": "string",
            "enum": [
              "asc",
              "desc"
            ],
            "default": "asc"
          }
        ],
        "responses": {
          "200": {
            "description": "",
            "schema": {
              "$ref": "#/definitions/TemplatesListResponse"
            }
          },
          "400": {
            "description": "Bad Request - Invalid request parameters or validation error",
            "examples": {
              "application/json": {
                "field_name": [
                  "Field related error message."
                ]
              }
            }
          },
          "401": {
            "description": "Unauthorized - Authentication credentials were not provided or are invalid",
            "examples": {
              "application/json": {
                "detail": "Authentication credentials were not provided."
              }
            }
          },
          "403": {
            "description": "Forbidden - You do not have permission to perform this action",
            "examples": {
              "application/json": {
                "detail": "You do not have permission for company 123"
              }
            }
          },
          "404": {
            "description": "Not Found - The requested resource was not found",
            "examples": {
              "application/json": {
                "detail": "Not found."
              }
            }
          },
          "429": {
            "description": "Too Many Requests - Rate limit exceeded",
            "examples": {
              "application/json": {
                "detail": "Request was throttled. Expected available in 60 seconds."
              }
            }
          },
          "500": {
            "description": "Internal Server Error - An unexpected error occurred",
            "examples": {
              "application/json": {
                "detail": "Internal server error."
              }
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/sat/{company_id}/templates/categories/": {
      "get": {
        "operationId": "Get Template Categories",
        "description": "Get template categories.<b>Scopes:</b><ul><li>company.view</li><li>partner.company.view</li></ul>",
        "parameters": [],
        "responses": {
          "200": {
            "description": "",
            "schema": {
              "$ref": "#/definitions/TemplateCategoriesResponse"
            }
          },
          "400": {
            "description": "Bad Request - Invalid request parameters or validation error",
            "examples": {
              "application/json": {
                "field_name": [
                  "Field related error message."
                ]
              }
            }
          },
          "401": {
            "description": "Unauthorized - Authentication credentials were not provided or are invalid",
            "examples": {
              "application/json": {
                "detail": "Authentication credentials were not provided."
              }
            }
          },
          "403": {
            "description": "Forbidden - You do not have permission to perform this action",
            "examples": {
              "application/json": {
                "detail": "You do not have permission for company 123"
              }
            }
          },
          "404": {
            "description": "Not Found - The requested resource was not found",
            "examples": {
              "application/json": {
                "detail": "Not found."
              }
            }
          },
          "429": {
            "description": "Too Many Requests - Rate limit exceeded",
            "examples": {
              "application/json": {
                "detail": "Request was throttled. Expected available in 60 seconds."
              }
            }
          },
          "500": {
            "description": "Internal Server Error - An unexpected error occurred",
            "examples": {
              "application/json": {
                "detail": "Internal server error."
              }
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/sat/{company_id}/trainings/": {
      "get": {
        "operationId": "Get Trainings List",
        "summary": "Get training list.",
        "description": "Returns a list of training content items filtered by vendor and locale IDs.\nThe results are paginated and include information about training availability\nbased on company licensing.<b>Scopes:</b><ul><li>company.view</li><li>partner.company.view</li></ul>",
        "parameters": [
          {
            "name": "vendor",
            "in": "query",
            "description": "Filter by training vendor codes.\n- `1` = NINJIO\n- `3` = Habitu8\n- `4` = Cybermaniacs Videos\n- `5` = Wizer\n- `6` = Ironscales",
            "required": true,
            "type": "integer",
            "enum": [
              6,
              5,
              1,
              3,
              4
            ]
          },
          {
            "name": "locale_ids",
            "in": "query",
            "description": "Filter by locale IDs.\n- Use numeric identifiers from the locale catalog\n- If not provided, company's selected locales will be used",
            "required": false,
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          {
            "name": "page",
            "in": "query",
            "required": false,
            "type": "integer",
            "default": 1,
            "minimum": 1
          },
          {
            "name": "page_size",
            "in": "query",
            "required": false,
            "type": "integer",
            "default": 25,
            "maximum": 50,
            "minimum": 1
          }
        ],
        "responses": {
          "200": {
            "description": "",
            "schema": {
              "$ref": "#/definitions/TrainingsListResponse"
            }
          },
          "400": {
            "description": "Bad Request - Invalid request parameters or validation error",
            "examples": {
              "application/json": {
                "field_name": [
                  "Field related error message."
                ]
              }
            }
          },
          "401": {
            "description": "Unauthorized - Authentication credentials were not provided or are invalid",
            "examples": {
              "application/json": {
                "detail": "Authentication credentials were not provided."
              }
            }
          },
          "403": {
            "description": "Forbidden - You do not have permission to perform this action",
            "examples": {
              "application/json": {
                "detail": "You do not have permission for company 123"
              }
            }
          },
          "404": {
            "description": "Not Found - The requested resource was not found",
            "examples": {
              "application/json": {
                "detail": "Not found."
              }
            }
          },
          "429": {
            "description": "Too Many Requests - Rate limit exceeded",
            "examples": {
              "application/json": {
                "detail": "Request was throttled. Expected available in 60 seconds."
              }
            }
          },
          "500": {
            "description": "Internal Server Error - An unexpected error occurred",
            "examples": {
              "application/json": {
                "detail": "Internal server error."
              }
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/sat/{company_id}/trainings/providers/": {
      "get": {
        "operationId": "Get Training Providers",
        "summary": "Get training providers.",
        "description": "Returns information about all available training content providers,\nincluding total count and available count of training items for each provider.\nThe available count is based on company licensing and free content availability.<b>Scopes:</b><ul><li>company.view</li><li>partner.company.view</li></ul>",
        "parameters": [],
        "responses": {
          "200": {
            "description": "",
            "schema": {
              "$ref": "#/definitions/TrainingProvidersResponse"
            }
          },
          "401": {
            "description": "Unauthorized - Authentication credentials were not provided or are invalid",
            "examples": {
              "application/json": {
                "detail": "Authentication credentials were not provided."
              }
            }
          },
          "403": {
            "description": "Forbidden - You do not have permission to perform this action",
            "examples": {
              "application/json": {
                "detail": "You do not have permission for company 123"
              }
            }
          },
          "404": {
            "description": "Not Found - The requested resource was not found",
            "examples": {
              "application/json": {
                "detail": "Not found."
              }
            }
          },
          "429": {
            "description": "Too Many Requests - Rate limit exceeded",
            "examples": {
              "application/json": {
                "detail": "Request was throttled. Expected available in 60 seconds."
              }
            }
          },
          "500": {
            "description": "Internal Server Error - An unexpected error occurred",
            "examples": {
              "application/json": {
                "detail": "Internal server error."
              }
            }
          }
        },
        "tags": [
          "SAT"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/settings/{company_id}/account-takeover/": {
      "get": {
        "operationId": "Get account takeover sensitivity settings",
        "description": "\nRetrieve the account takeover sensitivity settings for the specified company.\n<br/><br/>\n<b>Sensitivity Options:</b>\n<ul>\n    <li><b>1 (Aggressive):</b> Most sensitive - requires fewer alerts to trigger an incident</li>\n    <li><b>2 (Balanced):</b> Default sensitivity level</li>\n    <li><b>3 (Relaxed):</b> Least sensitive - requires more alerts to trigger an incident</li>\n</ul>\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.view</li>\n</ul>\n",
        "parameters": [],
        "responses": {
          "200": {
            "description": "Successful response containing account takeover sensitivity settings.",
            "schema": {
              "$ref": "#/definitions/AccountTakeoverSettings"
            },
            "examples": {
              "application/json": {
                "sensitivity": 2
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "put": {
        "operationId": "Update account takeover sensitivity settings",
        "description": "\nUpdate account takeover sensitivity settings for the specified company.\n<br/><br/>\n<b>Sensitivity Options:</b>\n<ul>\n    <li><b>1 (Aggressive):</b> Most sensitive - requires fewer alerts to trigger an incident</li>\n    <li><b>2 (Balanced):</b> Default sensitivity level</li>\n    <li><b>3 (Relaxed):</b> Least sensitive - requires more alerts to trigger an incident</li>\n</ul>\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n</ul>\n",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/AccountTakeoverSettings"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successfully updated account takeover sensitivity settings.",
            "schema": {
              "$ref": "#/definitions/AccountTakeoverSettings"
            },
            "examples": {
              "application/json": {
                "sensitivity": 3
              }
            }
          },
          "400": {
            "description": "Invalid request body - validation errors",
            "schema": {
              "type": "object",
              "properties": {
                "sensitivity": {
                  "description": "Field validation errors",
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            },
            "examples": {
              "application/json": {
                "sensitivity": [
                  "This field is required."
                ]
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/settings/{company_id}/allow-list/": {
      "get": {
        "operationId": "Get allow list settings",
        "description": "\nRetrieve the list of allow list settings for the specified company.\n<b>Scopes:</b><ul><li>company.all</li><li>company.view</li></ul>",
        "parameters": [
          {
            "name": "sort",
            "in": "query",
            "description": "Options: type | scope | date | allowed_for | noSorting",
            "required": false,
            "type": "string",
            "enum": [
              "type",
              "scope",
              "date",
              "allowed_for",
              "noSorting"
            ],
            "default": "noSorting"
          },
          {
            "name": "order",
            "in": "query",
            "description": "Options: desc | asc",
            "required": false,
            "type": "string",
            "enum": [
              "desc",
              "asc"
            ],
            "default": "desc"
          },
          {
            "name": "type",
            "in": "query",
            "description": "Filter by entry type.",
            "required": false,
            "type": "string",
            "enum": [
              "all",
              "ip",
              "domain",
              "address",
              "link_domain"
            ],
            "default": "all"
          },
          {
            "name": "search",
            "in": "query",
            "description": "Search term to filter entries by their value field (case-insensitive partial match).",
            "required": false,
            "type": "string",
            "x-nullable": true
          },
          {
            "name": "page",
            "in": "query",
            "description": "Page number for pagination results. Starts at 1.",
            "required": false,
            "type": "integer",
            "default": 1,
            "minimum": 1
          },
          {
            "name": "items_per_page",
            "in": "query",
            "description": "Number of items per page in pagination results. Min: 1, Max: 500, Default: 100.",
            "required": false,
            "type": "integer",
            "default": 100,
            "maximum": 500,
            "minimum": 1
          }
        ],
        "responses": {
          "200": {
            "description": "",
            "schema": {
              "$ref": "#/definitions/WhiteListResponse"
            }
          },
          "400": {
            "description": "Invalid query parameters, page must be a number, or page not found",
            "schema": {
              "type": "object",
              "properties": {
                "message": {
                  "description": "Error message for validation failure or pagination error",
                  "type": "string"
                }
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "post": {
        "operationId": "Create allow list settings",
        "description": "\nAdd a new entry to the allow list for the specified company.\n<b>Scopes:</b><ul><li>company.all</li><li>company.edit</li></ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/WhitelistAddRow"
            }
          }
        ],
        "responses": {
          "204": {
            "description": "Allow list entry successfully added.",
            "examples": {
              "application/json": {}
            }
          },
          "400": {
            "description": "Invalid request body or allowed records limit reached",
            "schema": {
              "type": "object",
              "properties": {
                "error_message": {
                  "description": "Error message for validation failure or limits reached",
                  "type": "string"
                }
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "put": {
        "operationId": "Update allow list entry",
        "description": "\nUpdate an existing allow list entry for the specified company.\n<b>Scopes:</b><ul><li>company.all</li><li>company.edit</li></ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/WhitelistUpdateRow"
            }
          }
        ],
        "responses": {
          "204": {
            "description": "Allow list entry successfully updated.",
            "examples": {
              "application/json": {}
            }
          },
          "400": {
            "description": "Invalid request body or whitelist entry not found",
            "schema": {
              "type": "object",
              "properties": {
                "error_message": {
                  "description": "Error message for validation failure or entry not found",
                  "type": "string"
                }
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "delete": {
        "operationId": "Delete allow list entries",
        "description": "\nDelete selected entries from the allow list for the specified company.\n<b>Scopes:</b><ul><li>company.all</li><li>company.edit</li></ul>",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/WhiteListDelete"
            }
          }
        ],
        "responses": {
          "204": {
            "description": "Allow list entries successfully deleted.",
            "examples": {
              "application/json": {}
            }
          },
          "400": {
            "description": "Invalid request data",
            "schema": {
              "type": "object",
              "properties": {
                "error_message": {
                  "description": "Error message for validation failure",
                  "type": "string"
                }
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/settings/{company_id}/challenged-alerts/": {
      "get": {
        "operationId": "Get challenged notification settings",
        "description": "\nRetrieve the list of email recipients configured for challenged alert notifications for the specified company.\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.view</li>\n</ul>\n",
        "parameters": [],
        "responses": {
          "200": {
            "description": "Successful response containing notification recipients.",
            "schema": {
              "$ref": "#/definitions/ChallengedSettings"
            },
            "examples": {
              "application/json": {
                "recipients": [
                  "email1@company1.com",
                  "email2@company1.com"
                ]
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "post": {
        "operationId": "Create challenged notification settings",
        "description": "\nSet the list of email recipients configured for challenged alert notifications for the specified company.\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n</ul>\n",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/ChallengedSettings"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful response containing the updated recipients list.",
            "schema": {
              "$ref": "#/definitions/ChallengedSettings"
            },
            "examples": {
              "application/json": {
                "recipients": [
                  "email1@company1.com",
                  "email2@company1.com"
                ]
              }
            }
          },
          "400": {
            "description": "Invalid request body - field validations failed",
            "schema": {
              "type": "object",
              "properties": {
                "recipients": {
                  "description": "Field validation errors",
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "put": {
        "operationId": "Append challenged notification settings",
        "description": "\nAppend email recipients to existing challenged alert notifications, removing duplicates, returning the updated list.\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n</ul>\n",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/ChallengedSettings"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful response containing the appended recipients list.",
            "schema": {
              "$ref": "#/definitions/ChallengedSettings"
            },
            "examples": {
              "application/json": {
                "recipients": [
                  "email1@company1.com",
                  "email2@company1.com",
                  "email3@company1.com"
                ]
              }
            }
          },
          "400": {
            "description": "Invalid request body - field validations failed",
            "schema": {
              "type": "object",
              "properties": {
                "recipients": {
                  "description": "Field validation errors",
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "delete": {
        "operationId": "Delete challenged notification settings",
        "description": "\nRemove all configured email recipients for challenged alert notifications. After deletion, the recipients list will be empty.\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n</ul>\n",
        "parameters": [],
        "responses": {
          "204": {
            "description": "Alert emails successfully cleared.",
            "examples": {
              "application/json": {}
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    },
    "/settings/{company_id}/incident-alerts/": {
      "get": {
        "operationId": "Get company notification settings",
        "description": "\nRetrieve the list of email recipients configured for incident alert notifications for the specified company.\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.view</li>\n</ul>\n",
        "parameters": [],
        "responses": {
          "200": {
            "description": "Successful response containing notification recipients.",
            "schema": {
              "$ref": "#/definitions/NotificationSettings"
            },
            "examples": {
              "application/json": {
                "recipients": [
                  "user1@validdomain.com",
                  "user2@validdomain.com"
                ]
              }
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "post": {
        "operationId": "Create company notification settings",
        "description": "\nSet the list of email recipients for incident alert notifications, replacing any existing recipients.\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n</ul>\n",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/NotificationSettings"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful response containing the updated recipients list.",
            "schema": {
              "$ref": "#/definitions/NotificationSettings"
            },
            "examples": {
              "application/json": {
                "recipients": [
                  "user1@validdomain.com",
                  "user2@validdomain.com"
                ]
              }
            }
          },
          "400": {
            "description": "Invalid request body - field validations failed",
            "examples": {
              "application/json": [
                {
                  "error_message": "explanation"
                }
              ]
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "put": {
        "operationId": "Append to company notification settings",
        "description": "\nAppend email recipients to the existing notification settings list, removing duplicates, returning the updated list.\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n</ul>\n",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "required": true,
            "schema": {
              "$ref": "#/definitions/NotificationSettings"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful response containing the appended recipients list.",
            "schema": {
              "$ref": "#/definitions/NotificationSettings"
            },
            "examples": {
              "application/json": {
                "recipients": [
                  "user1@validdomain.com",
                  "user2@validdomain.com",
                  "user3@validdomain.com"
                ]
              }
            }
          },
          "400": {
            "description": "Invalid request body - field validations failed",
            "examples": {
              "application/json": [
                {
                  "error_message": "explanation"
                }
              ]
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "delete": {
        "operationId": "Delete company notification settings",
        "description": "\nRemove all configured email recipients for incident alert notifications. After deletion, the recipients list will be empty.\n<br/><b>Scopes:</b>\n<ul>\n    <li>company.all</li>\n    <li>company.edit</li>\n</ul>\n",
        "parameters": [],
        "responses": {
          "204": {
            "description": "Alert emails successfully cleared.",
            "examples": {
              "application/json": {}
            }
          },
          "403": {
            "description": "Permission Denied",
            "examples": {
              "application/json": [
                {
                  "detail": "Missing JWT"
                },
                {
                  "detail": "You do not have permission to perform this action."
                },
                {
                  "message": "You do not have permission for company <company_id>"
                }
              ]
            }
          },
          "404": {
            "description": "Company was not found",
            "examples": {
              "application/json": [
                {
                  "message": "Company not found"
                }
              ]
            }
          },
          "429": {
            "description": "Too many requests",
            "examples": {
              "application/json": [
                {
                  "detail": "Request was throttled. Expected available in 60 seconds."
                }
              ]
            }
          }
        },
        "tags": [
          "Settings"
        ]
      },
      "parameters": [
        {
          "name": "company_id",
          "in": "path",
          "required": true,
          "type": "string"
        }
      ]
    }
  },
  "definitions": {
    "CampaignDetails": {
      "required": [
        "campaignID",
        "campaignName",
        "language",
        "companyId"
      ],
      "type": "object",
      "properties": {
        "campaignID": {
          "title": "Campaignid",
          "type": "integer"
        },
        "campaignName": {
          "title": "Campaignname",
          "type": "string",
          "minLength": 1
        },
        "campaignStatus": {
          "title": "Campaignstatus",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "flowType": {
          "title": "Flowtype",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "language": {
          "title": "Language",
          "type": "string",
          "minLength": 1
        },
        "maxEmailPerDay": {
          "title": "Maxemailperday",
          "description": "0 - Unlimited",
          "type": "integer",
          "readOnly": true
        },
        "endDate": {
          "title": "Enddate",
          "type": "string",
          "format": "date-time",
          "readOnly": true
        },
        "launchDate": {
          "title": "Launchdate",
          "type": "string",
          "format": "date-time",
          "readOnly": true
        },
        "emailsSent": {
          "title": "Emailssent",
          "type": "integer",
          "readOnly": true
        },
        "participants": {
          "title": "Participants",
          "type": "integer",
          "readOnly": true
        },
        "emailsBounced": {
          "title": "Emailsbounced",
          "type": "integer",
          "readOnly": true
        },
        "numberOfClickedParticipants": {
          "title": "Numberofclickedparticipants",
          "type": "integer",
          "readOnly": true
        },
        "numberOfTrainedParticipants": {
          "title": "Numberoftrainedparticipants",
          "type": "integer",
          "readOnly": true
        },
        "numberOfTrainedParticipatns": {
          "title": "Numberoftrainedparticipatns",
          "type": "integer",
          "readOnly": true
        },
        "numberOfReportedParticipants": {
          "title": "Numberofreportedparticipants",
          "type": "integer",
          "readOnly": true
        },
        "numberOfReadParticipants": {
          "title": "Numberofreadparticipants",
          "type": "integer",
          "readOnly": true
        },
        "numberOfDeleted": {
          "title": "Numberofdeleted",
          "type": "integer",
          "readOnly": true
        },
        "attackReadinessFirstReport": {
          "title": "Attackreadinessfirstreport",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "attackReadinessMitigationTime": {
          "title": "Attackreadinessmitigationtime",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "attackReadinessLuredBeforeMitigation": {
          "title": "Attackreadinessluredbeforemitigation",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "attackReadinessReportsToMitigate": {
          "title": "Attackreadinessreportstomitigate",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "companyId": {
          "title": "Companyid",
          "type": "integer"
        },
        "randomized": {
          "title": "Randomized",
          "type": "boolean",
          "readOnly": true
        }
      }
    },
    "CampaignDetailsPage": {
      "required": [
        "page",
        "total_pages",
        "campaigns"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "campaigns": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/CampaignDetails"
          }
        }
      }
    },
    "ParticipantsActionsFilters": {
      "type": "object",
      "properties": {
        "emails": {
          "description": "A list of recipient emails to filter by. Limited to 300 items.",
          "type": "array",
          "items": {
            "type": "string",
            "format": "email",
            "minLength": 1
          },
          "maxItems": 300
        }
      }
    },
    "ParticipantsActionsRequest": {
      "required": [
        "filters",
        "action"
      ],
      "type": "object",
      "properties": {
        "filters": {
          "$ref": "#/definitions/ParticipantsActionsFilters"
        },
        "action": {
          "title": "Action",
          "description": "The action to perform on participants:<br/>1 - Reported: Mark as reported<br/>2 - Manually Trained: Set training status to manually trained<br/>3 - Postponed: Set training status to postponed (requires expiration_date)<br/>4 - Revert Training: Revert Postponed and Manually Trained statuses only<br/>5 - Revert Reported: Revert Reported status set via appapi only",
          "type": "integer",
          "enum": [
            1,
            2,
            3,
            4,
            5
          ]
        },
        "expiration_date": {
          "title": "Expiration date",
          "description": "The expiration date of the Postponed Training status (ISO 8601 format, e.g. '2024-01-15'). Only valid when action is 3 (Postponed).",
          "type": "string",
          "format": "date",
          "x-nullable": true
        }
      }
    },
    "CampaignParticipantsDetails": {
      "type": "object",
      "properties": {
        "internalID": {
          "title": "Internalid",
          "type": "string",
          "minLength": 1
        },
        "name": {
          "title": "Name",
          "type": "string",
          "minLength": 1
        },
        "displayName": {
          "title": "Displayname",
          "type": "string",
          "minLength": 1
        },
        "lastUpdate": {
          "title": "Last Update",
          "description": "date-time format %b %d, %Y %H:%M",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        },
        "title": {
          "title": "Title",
          "type": "string",
          "minLength": 1
        },
        "department": {
          "title": "Department",
          "type": "string",
          "minLength": 1
        },
        "company": {
          "title": "Company",
          "type": "string",
          "minLength": 1
        },
        "manager": {
          "title": "Manager",
          "type": "string",
          "minLength": 1
        },
        "office": {
          "title": "Office",
          "type": "string",
          "minLength": 1
        },
        "country": {
          "title": "Country",
          "type": "string",
          "x-nullable": true
        },
        "city": {
          "title": "City",
          "type": "string",
          "x-nullable": true
        },
        "sentAt": {
          "title": "Sent At",
          "description": "date-time format %b %d, %Y %H:%M",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        },
        "opened": {
          "title": "Opened",
          "type": "string",
          "enum": [
            "Yes",
            "No"
          ]
        },
        "openedAt": {
          "title": "Opened At",
          "description": "date-time format %b %d, %Y %H:%M",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        },
        "enteredDetails": {
          "title": "Entereddetails",
          "type": "string",
          "enum": [
            "Yes",
            "No"
          ]
        },
        "trainingModule": {
          "title": "Trainingmodule",
          "type": "string",
          "minLength": 1
        },
        "trainingVideoStarted": {
          "title": "Trainingvideostarted",
          "type": "string",
          "enum": [
            "Yes",
            "No"
          ]
        },
        "awarenessLevel": {
          "title": "Awarenesslevel",
          "type": "string",
          "enum": [
            "Beginner Level",
            "Mid Level",
            "Expert Level"
          ],
          "readOnly": true,
          "x-nullable": true
        },
        "customTags": {
          "title": "Customtags",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "reported": {
          "title": "Reported",
          "type": "string",
          "enum": [
            "Yes",
            "No"
          ],
          "x-nullable": true
        },
        "reportedTime": {
          "title": "Reported Time",
          "description": "date-time format %b %d, %Y %H:%M",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        },
        "read": {
          "title": "Read",
          "type": "string",
          "enum": [
            "Yes",
            "No"
          ]
        },
        "clicked": {
          "title": "Clicked",
          "type": "string",
          "enum": [
            "Yes",
            "No"
          ],
          "x-nullable": true
        },
        "clickedTime": {
          "title": "Clicked Time",
          "description": "date-time format %b %d, %Y %H:%M",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        },
        "resendTrainingDates": {
          "description": "date-time format %b %d, %Y %H:%M",
          "type": "array",
          "items": {
            "type": "string",
            "format": "date-time"
          }
        },
        "deleted": {
          "title": "Deleted",
          "type": "string",
          "enum": [
            "Yes",
            "No"
          ],
          "x-nullable": true
        },
        "trained": {
          "title": "Trained",
          "type": "string",
          "enum": [
            "Postponed",
            "Manually trained",
            "Yes",
            "No",
            "N/A",
            "Scheduled to send"
          ],
          "readOnly": true,
          "x-nullable": true
        },
        "trainingCompletionDate": {
          "title": "Training Completion Date",
          "description": "date-time format %b %d, %Y %H:%M",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        },
        "trainingScore": {
          "title": "Trainingscore",
          "type": "integer",
          "readOnly": true,
          "x-nullable": true
        },
        "trainingDuration": {
          "title": "Trainingduration",
          "type": "integer"
        },
        "trainingStartedOn": {
          "title": "Training Started On",
          "description": "date-time format %b %d, %Y %H:%M",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        },
        "email": {
          "title": "Email",
          "type": "string",
          "minLength": 1
        },
        "template": {
          "title": "Template",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "userIp": {
          "title": "Userip",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "CampaignParticipantsDetailsPage": {
      "required": [
        "page",
        "total_pages",
        "campaign_id",
        "participants"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "campaign_id": {
          "title": "Campaign id",
          "type": "integer"
        },
        "participants": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/CampaignParticipantsDetails"
          }
        }
      }
    },
    "CreateCompany": {
      "required": [
        "name",
        "ownerEmail",
        "ownerFirstName",
        "ownerLastName",
        "domain"
      ],
      "type": "object",
      "properties": {
        "name": {
          "title": "Name",
          "type": "string",
          "maxLength": 100,
          "minLength": 1
        },
        "ownerEmail": {
          "title": "Owneremail",
          "type": "string",
          "maxLength": 75,
          "minLength": 1
        },
        "ownerFirstName": {
          "title": "Ownerfirstname",
          "type": "string",
          "maxLength": 30,
          "minLength": 1
        },
        "ownerLastName": {
          "title": "Ownerlastname",
          "type": "string",
          "maxLength": 30,
          "minLength": 1
        },
        "domain": {
          "title": "Domain",
          "type": "string",
          "maxLength": 50,
          "minLength": 1
        },
        "partner_id": {
          "title": "Partner id",
          "type": "string",
          "default": "me",
          "minLength": 1
        },
        "allowedDomains": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        },
        "country": {
          "title": "Country",
          "description": "ISO 3166 country name",
          "type": "string",
          "minLength": 1
        },
        "autopilotEnabled": {
          "title": "Autopilotenabled",
          "type": "boolean"
        },
        "licensedMailboxes": {
          "title": "Licensedmailboxes",
          "description": "Employee/Mailboxes count limit",
          "type": "integer",
          "default": 500
        },
        "silentMode": {
          "title": "Silentmode",
          "type": "boolean"
        },
        "is_starter": {
          "title": "Is starter",
          "type": "boolean"
        },
        "silentModeMsg": {
          "title": "Silentmodemsg",
          "type": "boolean"
        },
        "planType": {
          "title": "Plantype",
          "type": "integer",
          "enum": [
            1,
            2,
            3,
            4,
            5,
            6,
            7
          ]
        },
        "planExpiration": {
          "title": "Planexpiration",
          "type": "string",
          "format": "date-time"
        }
      }
    },
    "CreateCompanyResponse": {
      "required": [
        "company_id",
        "admin_password"
      ],
      "type": "object",
      "properties": {
        "company_id": {
          "title": "Company id",
          "type": "integer"
        },
        "admin_password": {
          "title": "Admin password",
          "type": "string",
          "maxLength": 32,
          "minLength": 1
        }
      }
    },
    "Company": {
      "required": [
        "name",
        "domain"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "name": {
          "title": "Name",
          "type": "string",
          "minLength": 1
        },
        "domain": {
          "title": "Domain",
          "type": "string",
          "maxLength": 50,
          "minLength": 1
        },
        "ownerEmail": {
          "title": "Owneremail",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "ownerName": {
          "title": "Ownername",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "country": {
          "title": "Country",
          "description": "ISO 3166 country name",
          "type": "string",
          "minLength": 1
        },
        "registrationDate": {
          "title": "Registrationdate",
          "type": "string",
          "format": "date-time",
          "readOnly": true
        },
        "partner_id": {
          "title": "Partner id",
          "type": "integer",
          "readOnly": true
        }
      }
    },
    "CompanyList": {
      "required": [
        "companies"
      ],
      "type": "object",
      "properties": {
        "companies": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/Company"
          }
        }
      }
    },
    "CompanyV2": {
      "required": [
        "name",
        "domain",
        "ownerEmail",
        "ownerName",
        "partner_id"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "name": {
          "title": "Name",
          "type": "string",
          "minLength": 1
        },
        "domain": {
          "title": "Domain",
          "type": "string",
          "maxLength": 50,
          "minLength": 1
        },
        "ownerEmail": {
          "title": "Owneremail",
          "type": "string",
          "minLength": 1
        },
        "ownerName": {
          "title": "Ownername",
          "type": "string",
          "minLength": 1
        },
        "country": {
          "title": "Country",
          "description": "ISO 3166 country name",
          "type": "string",
          "minLength": 1
        },
        "registrationDate": {
          "title": "Registrationdate",
          "type": "string",
          "format": "date-time"
        },
        "partner_id": {
          "title": "Partner id",
          "type": "integer"
        },
        "planExpirationDate": {
          "title": "Planexpirationdate",
          "type": "string",
          "format": "date-time"
        },
        "trialPlanExpirationDate": {
          "title": "Trialplanexpirationdate",
          "type": "string",
          "format": "date-time"
        }
      }
    },
    "CompanyListV2Response": {
      "required": [
        "total_pages",
        "page",
        "data"
      ],
      "type": "object",
      "properties": {
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "data": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/CompanyV2"
          }
        }
      }
    },
    "EmptyResponse": {
      "type": "object",
      "properties": {}
    },
    "CompanyEmail911": {
      "required": [
        "email"
      ],
      "type": "object",
      "properties": {
        "email": {
          "title": "Email",
          "type": "string",
          "format": "email",
          "minLength": 1
        }
      }
    },
    "AutoSyncStatusResponse": {
      "required": [
        "in_progress",
        "mailboxes_total_count",
        "protected_mailboxes_count",
        "enabled_mailboxes_count",
        "synced_mailboxes_count",
        "failed_mailboxes_count",
        "last_synced_at"
      ],
      "type": "object",
      "properties": {
        "in_progress": {
          "title": "In progress",
          "type": "boolean"
        },
        "mailboxes_total_count": {
          "title": "Mailboxes total count",
          "type": "integer"
        },
        "protected_mailboxes_count": {
          "title": "Protected mailboxes count",
          "type": "integer"
        },
        "enabled_mailboxes_count": {
          "title": "Enabled mailboxes count",
          "type": "integer"
        },
        "synced_mailboxes_count": {
          "title": "Synced mailboxes count",
          "type": "integer"
        },
        "failed_mailboxes_count": {
          "title": "Failed mailboxes count",
          "type": "integer"
        },
        "last_synced_at": {
          "title": "Last synced at",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        }
      }
    },
    "AutoSyncGroup": {
      "required": [
        "id",
        "display_name"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "display_name": {
          "title": "Display name",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "ActivateAutoSyncRequest": {
      "required": [
        "sync_shared",
        "trigger_now"
      ],
      "type": "object",
      "properties": {
        "sync_shared": {
          "title": "Sync shared",
          "type": "boolean"
        },
        "trigger_now": {
          "title": "Trigger now",
          "type": "boolean"
        },
        "groups": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/AutoSyncGroup"
          }
        }
      }
    },
    "AutoSyncGroupsResponse": {
      "required": [
        "groups",
        "page",
        "total_pages",
        "all_groups_count"
      ],
      "type": "object",
      "properties": {
        "groups": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/AutoSyncGroup"
          }
        },
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "all_groups_count": {
          "title": "All groups count",
          "type": "integer"
        }
      }
    },
    "AutoSyncEmailList": {
      "required": [
        "first_name",
        "last_name",
        "email",
        "change_date"
      ],
      "type": "object",
      "properties": {
        "first_name": {
          "title": "First name",
          "type": "string",
          "minLength": 1
        },
        "last_name": {
          "title": "Last name",
          "type": "string",
          "minLength": 1
        },
        "email": {
          "title": "Email",
          "type": "string",
          "format": "email",
          "minLength": 1
        },
        "change_date": {
          "title": "Change date",
          "type": "string",
          "format": "date-time"
        }
      }
    },
    "AutoSyncEmailListResponse": {
      "required": [
        "page",
        "total_pages",
        "emails"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "emails": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/AutoSyncEmailList"
          }
        }
      }
    },
    "GetCompanyFeature": {
      "type": "object",
      "properties": {
        "silentMode": {
          "title": "Silentmode",
          "type": "boolean"
        },
        "silentModeMsg": {
          "title": "Silentmodemsg",
          "type": "boolean"
        },
        "ato": {
          "title": "Ato",
          "type": "boolean"
        },
        "serviceManagement": {
          "title": "Servicemanagement",
          "type": "boolean"
        },
        "trainingCampaignsWizer": {
          "title": "Trainingcampaignswizer",
          "type": "boolean"
        },
        "api": {
          "title": "Api",
          "type": "boolean"
        },
        "themisCoPilot": {
          "title": "Themiscopilot",
          "type": "boolean"
        },
        "attachmentsScan": {
          "title": "Attachmentsscan",
          "type": "boolean"
        },
        "linksScan": {
          "title": "Linksscan",
          "type": "boolean"
        },
        "STbundle": {
          "title": "Stbundle",
          "type": "boolean"
        },
        "SATBundlePlus": {
          "title": "Satbundleplus",
          "type": "boolean"
        },
        "AiEmpowerBundle": {
          "title": "Aiempowerbundle",
          "type": "boolean"
        },
        "autopilotEnabled": {
          "title": "Autopilotenabled",
          "type": "boolean"
        }
      }
    },
    "UpdateCompanyFeature": {
      "required": [
        "feature",
        "state"
      ],
      "type": "object",
      "properties": {
        "feature": {
          "title": "Feature",
          "type": "string",
          "maxLength": 100,
          "minLength": 1
        },
        "state": {
          "title": "State",
          "type": "string",
          "maxLength": 75,
          "minLength": 1
        }
      }
    },
    "CompanyManifestGenerator": {
      "required": [
        "report_button",
        "add_in_description",
        "report_phishing_caption",
        "provider_name"
      ],
      "type": "object",
      "properties": {
        "report_button": {
          "title": "Report button",
          "type": "string",
          "minLength": 1
        },
        "add_in_description": {
          "title": "Add in description",
          "type": "string",
          "minLength": 1
        },
        "report_phishing_caption": {
          "title": "Report phishing caption",
          "type": "string",
          "minLength": 1
        },
        "provider_name": {
          "title": "Provider name",
          "type": "string",
          "minLength": 1
        },
        "logo": {
          "title": "Logo",
          "description": "Base64-encoded content",
          "type": "string"
        }
      }
    },
    "LicenseDetails": {
      "required": [
        "id",
        "trialExpiration",
        "ironSchoolExpiration",
        "ironSchoolPremiumExpiration",
        "ironTrapsExpiration",
        "federationExpiration",
        "ironSightsExpiration",
        "ironShieldExpiration",
        "themisExpiration",
        "testMode",
        "mailboxLimit",
        "planType",
        "trialType",
        "is_partner"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "type": "integer"
        },
        "trialExpiration": {
          "title": "Trialexpiration",
          "type": "string",
          "format": "date-time"
        },
        "ironSchoolExpiration": {
          "title": "Ironschoolexpiration",
          "type": "string",
          "format": "date-time"
        },
        "ironSchoolPremiumExpiration": {
          "title": "Ironschoolpremiumexpiration",
          "type": "string",
          "format": "date-time"
        },
        "ironTrapsExpiration": {
          "title": "Irontrapsexpiration",
          "type": "string",
          "format": "date-time"
        },
        "federationExpiration": {
          "title": "Federationexpiration",
          "type": "string",
          "format": "date-time"
        },
        "ironSightsExpiration": {
          "title": "Ironsightsexpiration",
          "type": "string",
          "format": "date-time"
        },
        "ironShieldExpiration": {
          "title": "Ironshieldexpiration",
          "type": "string",
          "format": "date-time"
        },
        "themisExpiration": {
          "title": "Themisexpiration",
          "type": "string",
          "format": "date-time"
        },
        "testMode": {
          "title": "Testmode",
          "type": "boolean"
        },
        "mailboxLimit": {
          "title": "Mailboxlimit",
          "description": "Employee/Mailboxes count limit",
          "type": "integer"
        },
        "is_freemium": {
          "title": "Is freemium",
          "type": "boolean"
        },
        "planType": {
          "title": "Plantype",
          "type": "string",
          "minLength": 1
        },
        "trialType": {
          "title": "Trialtype",
          "type": "string",
          "minLength": 1
        },
        "is_partner": {
          "title": "Is partner",
          "type": "boolean"
        }
      }
    },
    "CompanyDetails": {
      "required": [
        "openIncidentCount",
        "highPriorityIncidentCount",
        "mediumPriorityIncidentCount",
        "lowPriorityIncidentCount",
        "activeAttacksCount",
        "license",
        "protectedMailboxes",
        "activeMailboxes",
        "lastMailboxSyncDate"
      ],
      "type": "object",
      "properties": {
        "openIncidentCount": {
          "title": "Openincidentcount",
          "description": "Count of unclassified incidents",
          "type": "integer"
        },
        "highPriorityIncidentCount": {
          "title": "Highpriorityincidentcount",
          "type": "integer"
        },
        "mediumPriorityIncidentCount": {
          "title": "Mediumpriorityincidentcount",
          "type": "integer"
        },
        "lowPriorityIncidentCount": {
          "title": "Lowpriorityincidentcount",
          "type": "integer"
        },
        "activeAttacksCount": {
          "title": "Activeattackscount",
          "type": "integer"
        },
        "license": {
          "$ref": "#/definitions/LicenseDetails"
        },
        "protectedMailboxes": {
          "title": "Protectedmailboxes",
          "description": "Count of protected mailboxes",
          "type": "integer"
        },
        "activeMailboxes": {
          "title": "Activemailboxes",
          "description": "Count of active profiles in the company",
          "type": "integer"
        },
        "lastMailboxSyncDate": {
          "title": "Lastmailboxsyncdate",
          "description": "ISO Format of last mailbox sync date",
          "type": "string",
          "format": "date-time"
        }
      }
    },
    "EmailsDetailFromElastic": {
      "type": "object",
      "properties": {
        "arrival_date": {
          "title": "Arrival date",
          "type": "string",
          "format": "date-time",
          "readOnly": true
        },
        "incident_id": {
          "title": "Incident id",
          "type": "integer",
          "readOnly": true
        },
        "subject": {
          "title": "Subject",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "sender_email": {
          "title": "Sender email",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "recipient_name": {
          "title": "Recipient name",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "recipient_email": {
          "title": "Recipient email",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "primary_threat_type": {
          "title": "Primary threat type",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "is_scanback": {
          "title": "Is scanback",
          "type": "boolean",
          "readOnly": true
        },
        "classification": {
          "title": "Classification",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "incident_state": {
          "title": "Incident state",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "resolution": {
          "title": "Resolution",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "sender_ip": {
          "title": "Sender ip",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "reported_by": {
          "title": "Reported by",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "mailbox_id": {
          "title": "Mailbox id",
          "type": "integer",
          "readOnly": true
        },
        "department": {
          "title": "Department",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "remediated_time": {
          "title": "Remediated time",
          "type": "string",
          "format": "date-time",
          "readOnly": true
        },
        "mitigation_id": {
          "title": "Mitigation id",
          "type": "integer",
          "readOnly": true
        },
        "challenged_type": {
          "title": "Challenged type",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "challenged_date": {
          "title": "Challenged date",
          "type": "string",
          "format": "date-time",
          "readOnly": true,
          "x-nullable": true
        },
        "challenged_by": {
          "title": "Challenged by",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "challenged_reason": {
          "title": "Challenged reason",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "challenged_comment": {
          "title": "Challenged comment",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "opened_on": {
          "title": "Opened on",
          "description": "Get the timestamp when the email was opened/read by the user (before remediation)",
          "type": "string",
          "format": "date-time",
          "readOnly": true,
          "x-nullable": true
        }
      }
    },
    "EmailsResponse": {
      "required": [
        "emails",
        "page",
        "total_pages",
        "total_count"
      ],
      "type": "object",
      "properties": {
        "emails": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/EmailsDetailFromElastic"
          }
        },
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "total_count": {
          "title": "Total count",
          "type": "integer"
        }
      }
    },
    "JwtRequest": {
      "required": [
        "key",
        "scopes"
      ],
      "type": "object",
      "properties": {
        "key": {
          "title": "Key",
          "type": "string",
          "minLength": 1
        },
        "scopes": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        }
      }
    },
    "AccountDetails": {
      "description": "Account information",
      "required": [
        "name",
        "title",
        "department",
        "email",
        "country",
        "phone_number"
      ],
      "type": "object",
      "properties": {
        "name": {
          "title": "Name",
          "description": "Full name of the account holder",
          "type": "string",
          "minLength": 1
        },
        "title": {
          "title": "Title",
          "description": "Job title",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "department": {
          "title": "Department",
          "description": "Department",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "email": {
          "title": "Email",
          "description": "Email address",
          "type": "string",
          "format": "email",
          "minLength": 1
        },
        "country": {
          "title": "Country",
          "description": "Country",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "phone_number": {
          "title": "Phone number",
          "description": "Phone number",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        }
      }
    },
    "AlertDetail": {
      "description": "List of alert details",
      "required": [
        "ip",
        "location",
        "logon_time"
      ],
      "type": "object",
      "properties": {
        "ip": {
          "title": "Ip",
          "description": "IP address associated with the alert",
          "type": "string",
          "minLength": 1
        },
        "location": {
          "title": "Location",
          "description": "Geographic location",
          "type": "string",
          "minLength": 1
        },
        "logon_time": {
          "title": "Logon time",
          "description": "Time of the logon event",
          "type": "string",
          "format": "date-time"
        }
      }
    },
    "Alert": {
      "description": "List of security alerts",
      "required": [
        "id",
        "title",
        "description",
        "type",
        "details",
        "created"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "description": "Unique alert identifier",
          "type": "integer"
        },
        "title": {
          "title": "Title",
          "description": "Alert title",
          "type": "string",
          "minLength": 1
        },
        "description": {
          "title": "Description",
          "description": "Alert description",
          "type": "string",
          "minLength": 1
        },
        "type": {
          "title": "Type",
          "description": "Alert type identifier",
          "type": "integer"
        },
        "details": {
          "description": "List of alert details",
          "type": "array",
          "items": {
            "$ref": "#/definitions/AlertDetail"
          }
        },
        "created": {
          "title": "Created",
          "description": "Alert creation timestamp",
          "type": "string",
          "format": "date-time"
        }
      }
    },
    "Assignee": {
      "description": "Assigned user information",
      "required": [
        "id",
        "email",
        "first_name",
        "last_name"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "description": "User ID",
          "type": "integer",
          "x-nullable": true
        },
        "email": {
          "title": "Email",
          "description": "User email",
          "type": "string",
          "format": "email",
          "minLength": 1,
          "x-nullable": true
        },
        "first_name": {
          "title": "First name",
          "description": "First name",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "last_name": {
          "title": "Last name",
          "description": "Last name",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        }
      }
    },
    "AccountTakeoverIncidentDetails": {
      "description": "Account takeover incident details",
      "required": [
        "id",
        "account_details",
        "alerts",
        "state",
        "original_state",
        "resolved_by",
        "resolved_on",
        "created",
        "assignee"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "description": "Incident identifier",
          "type": "integer"
        },
        "account_details": {
          "$ref": "#/definitions/AccountDetails"
        },
        "alerts": {
          "description": "List of security alerts",
          "type": "array",
          "items": {
            "$ref": "#/definitions/Alert"
          }
        },
        "state": {
          "title": "State",
          "description": "Incident state",
          "type": "integer"
        },
        "original_state": {
          "title": "Original state",
          "description": "Original incident state",
          "type": "integer"
        },
        "resolved_by": {
          "title": "Resolved by",
          "description": "Name of resolver",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "resolved_on": {
          "title": "Resolved on",
          "description": "Resolution timestamp",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        },
        "created": {
          "title": "Created",
          "description": "Incident creation timestamp",
          "type": "string",
          "format": "date-time"
        },
        "assignee": {
          "$ref": "#/definitions/Assignee"
        }
      }
    },
    "FilterOptions": {
      "description": "Available filter options",
      "required": [
        "titles",
        "locations",
        "ips"
      ],
      "type": "object",
      "properties": {
        "titles": {
          "description": "Available alert titles for filtering",
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        },
        "locations": {
          "description": "Available locations for filtering",
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        },
        "ips": {
          "description": "Available IP addresses for filtering",
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        }
      }
    },
    "AccountTakeoverDetailsResponse": {
      "required": [
        "incident_details",
        "filter_options",
        "pages_count",
        "page",
        "items_per_page"
      ],
      "type": "object",
      "properties": {
        "incident_details": {
          "$ref": "#/definitions/AccountTakeoverIncidentDetails"
        },
        "filter_options": {
          "$ref": "#/definitions/FilterOptions"
        },
        "pages_count": {
          "title": "Pages count",
          "description": "Total number of pages",
          "type": "integer"
        },
        "page": {
          "title": "Page",
          "description": "Current page number",
          "type": "integer"
        },
        "items_per_page": {
          "title": "Items per page",
          "description": "Number of items per page",
          "type": "integer"
        }
      }
    },
    "AccountTakeoverRemediation": {
      "required": [
        "state"
      ],
      "type": "object",
      "properties": {
        "state": {
          "title": "State",
          "description": "ATO remediation state: 2 (Safe), 3 (Compromised)",
          "type": "integer",
          "enum": [
            2,
            3
          ]
        },
        "action": {
          "title": "Action",
          "description": "ATO remediation action: 2 (DISABLE_ACCOUNT), 3 (SIGN_OUT)",
          "type": "integer",
          "enum": [
            3,
            2
          ],
          "x-nullable": true
        }
      }
    },
    "AccountTakeoverRemediationResponse": {
      "required": [
        "state"
      ],
      "type": "object",
      "properties": {
        "state": {
          "title": "State",
          "description": "Updated incident state: 2 (Safe), 3 (Compromised)",
          "type": "integer",
          "enum": [
            2,
            3
          ]
        }
      }
    },
    "AccountTakeoverRemediationError": {
      "required": [
        "data"
      ],
      "type": "object",
      "properties": {
        "data": {
          "title": "Data",
          "description": "Validation errors for request fields",
          "type": "object",
          "additionalProperties": {
            "description": "Field validation errors",
            "type": "array",
            "items": {
              "type": "string",
              "minLength": 1
            }
          }
        }
      }
    },
    "IncidentClassification": {
      "required": [
        "classification",
        "prev_classification",
        "classifying_user_email"
      ],
      "type": "object",
      "properties": {
        "classification": {
          "title": "Classification",
          "description": "The same classification can be achieved using multiple values:\n<table>\n  <thead>\n    <tr>\n      <th scope=\"col\">Value</th>\n      <th scope=\"col\">Classification</th>\n    </tr>\n  </thead>\n  <tbody>\n  <tr><td><li>report</li><li>unclassified</li></td><td>Report</td></tr><tr><td><li>attack</li><li>phishing</li><li>malicious</li></td><td>Attack</td></tr><tr><td><li>safe</li><li>fp</li><li>false positive</li></td><td>False Positive</td></tr><tr><td><li>spam</li></td><td>Spam</td></tr><tr><td><li>close phishing</li></td><td>Close Phishing</td></tr>\n  </tbody>\n</table>\n",
          "type": "string",
          "minLength": 1
        },
        "prev_classification": {
          "title": "Prev classification",
          "type": "string",
          "enum": [
            "Attack",
            "False Positive",
            "Spam",
            "Close Phishing",
            "Report"
          ]
        },
        "classifying_user_email": {
          "title": "Classifying user email",
          "type": "string",
          "format": "email",
          "minLength": 1
        }
      }
    },
    "MailServer": {
      "required": [
        "host",
        "ip"
      ],
      "type": "object",
      "properties": {
        "host": {
          "title": "Host",
          "type": "string",
          "minLength": 1
        },
        "ip": {
          "title": "Ip",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "FederationDetails": {
      "required": [
        "companies_affected",
        "companies_marked_phishing",
        "companies_marked_spam",
        "companies_marked_fp",
        "companies_unclassified",
        "phishing_ratio"
      ],
      "type": "object",
      "properties": {
        "companies_affected": {
          "title": "Companies affected",
          "type": "integer"
        },
        "companies_marked_phishing": {
          "title": "Companies marked phishing",
          "type": "integer"
        },
        "companies_marked_spam": {
          "title": "Companies marked spam",
          "type": "integer"
        },
        "companies_marked_fp": {
          "title": "Companies marked fp",
          "type": "integer"
        },
        "companies_unclassified": {
          "title": "Companies unclassified",
          "type": "integer"
        },
        "phishing_ratio": {
          "title": "Phishing ratio",
          "type": "number",
          "format": "decimal"
        }
      }
    },
    "Header": {
      "required": [
        "name",
        "value"
      ],
      "type": "object",
      "properties": {
        "name": {
          "title": "Name",
          "type": "string",
          "minLength": 1
        },
        "value": {
          "title": "Value",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "ReportedEmail": {
      "required": [
        "name",
        "email",
        "subject",
        "sender_email",
        "mail_server",
        "headers"
      ],
      "type": "object",
      "properties": {
        "name": {
          "title": "Name",
          "type": "string",
          "minLength": 1
        },
        "email": {
          "title": "Email",
          "type": "string",
          "minLength": 1
        },
        "subject": {
          "title": "Subject",
          "type": "string",
          "minLength": 1
        },
        "sender_email": {
          "title": "Sender email",
          "type": "string",
          "minLength": 1
        },
        "mail_server": {
          "$ref": "#/definitions/MailServer"
        },
        "headers": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/Header"
          }
        }
      }
    },
    "Link": {
      "required": [
        "url",
        "name",
        "scan_result"
      ],
      "type": "object",
      "properties": {
        "url": {
          "title": "Url",
          "type": "string",
          "minLength": 1
        },
        "name": {
          "title": "Name",
          "type": "string",
          "minLength": 1
        },
        "scan_result": {
          "title": "Scan result",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        }
      }
    },
    "Attachment": {
      "required": [
        "file_name",
        "file_size",
        "md5",
        "scan_result"
      ],
      "type": "object",
      "properties": {
        "file_name": {
          "title": "File name",
          "type": "string",
          "minLength": 1
        },
        "file_size": {
          "title": "File size",
          "type": "integer"
        },
        "md5": {
          "title": "Md5",
          "type": "string",
          "minLength": 1
        },
        "scan_result": {
          "title": "Scan result",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        }
      }
    },
    "AffectedMailbox": {
      "description": "List of affected mailboxes (mitigations) for this incident",
      "required": [
        "id",
        "recipient",
        "recipient_id",
        "employee_active",
        "first_reported",
        "not_found",
        "can_recluster"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "description": "Mitigation ID",
          "type": "integer"
        },
        "recipient": {
          "title": "Recipient",
          "description": "Email address of the affected mailbox",
          "type": "string",
          "minLength": 1
        },
        "recipient_id": {
          "title": "Recipient id",
          "description": "Employee ID",
          "type": "integer"
        },
        "employee_active": {
          "title": "Employee active",
          "description": "employee is active",
          "type": "boolean"
        },
        "first_reported": {
          "title": "First reported",
          "description": "Is first reporter",
          "type": "boolean"
        },
        "not_found": {
          "title": "Not found",
          "description": "Email not found in mailbox",
          "type": "boolean"
        },
        "can_recluster": {
          "title": "Can recluster",
          "description": "Email can be reclustered back to the original incident. False for the root email (first_reported) of a reclassified incident.",
          "type": "boolean"
        }
      }
    },
    "IncidentDetails": {
      "required": [
        "company_id",
        "company_name",
        "incident_id",
        "classification",
        "first_reported_by",
        "first_reported_date",
        "affected_mailbox_count",
        "sender_reputation",
        "banner_displayed",
        "sender_email",
        "reply_to",
        "spf_result",
        "sender_is_internal",
        "themis_proba",
        "themis_verdict",
        "mail_server",
        "federation",
        "reports",
        "links",
        "attachments",
        "original_email_body",
        "email_body_text",
        "reported_by_end_user",
        "reporter_name",
        "challenged_type",
        "challenged_events",
        "first_challenged_date",
        "related_incidents",
        "resolved_by",
        "resolved_on",
        "reclassified_by",
        "reclassified_on",
        "affected_mailboxes",
        "is_reclassified",
        "original_cluster_incident_id",
        "can_revert",
        "revert_blocked_reason"
      ],
      "type": "object",
      "properties": {
        "company_id": {
          "title": "Company id",
          "type": "integer"
        },
        "company_name": {
          "title": "Company name",
          "type": "string",
          "minLength": 1
        },
        "incident_id": {
          "title": "Incident id",
          "type": "integer"
        },
        "classification": {
          "title": "Classification",
          "type": "string",
          "minLength": 1
        },
        "first_reported_by": {
          "title": "First reported by",
          "type": "string",
          "minLength": 1
        },
        "first_reported_date": {
          "title": "First reported date",
          "type": "string",
          "format": "date-time"
        },
        "affected_mailbox_count": {
          "title": "Affected mailbox count",
          "type": "integer"
        },
        "sender_reputation": {
          "title": "Sender reputation",
          "type": "string",
          "minLength": 1
        },
        "banner_displayed": {
          "title": "Banner displayed",
          "type": "string",
          "minLength": 1
        },
        "sender_email": {
          "title": "Sender email",
          "type": "string",
          "minLength": 1
        },
        "reply_to": {
          "title": "Reply to",
          "type": "string",
          "minLength": 1
        },
        "spf_result": {
          "title": "Spf result",
          "type": "string",
          "minLength": 1
        },
        "sender_is_internal": {
          "title": "Sender is internal",
          "type": "boolean"
        },
        "themis_proba": {
          "title": "Themis proba",
          "type": "number",
          "format": "decimal"
        },
        "themis_verdict": {
          "title": "Themis verdict",
          "type": "string",
          "minLength": 1
        },
        "mail_server": {
          "$ref": "#/definitions/MailServer"
        },
        "federation": {
          "$ref": "#/definitions/FederationDetails"
        },
        "reports": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/ReportedEmail"
          }
        },
        "links": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/Link"
          }
        },
        "attachments": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/Attachment"
          }
        },
        "original_email_body": {
          "title": "Original email body",
          "type": "string",
          "minLength": 1
        },
        "email_body_text": {
          "title": "Email body text",
          "type": "string",
          "minLength": 1
        },
        "reported_by_end_user": {
          "title": "Reported by end user",
          "type": "boolean"
        },
        "reporter_name": {
          "title": "Reporter name",
          "type": "string",
          "minLength": 1
        },
        "challenged_type": {
          "title": "Challenged type",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "challenged_events": {
          "description": "List of challenged events, each containing challenged_date, challenged_by, challenged_reason, and challenged_comment",
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": {
              "type": "string",
              "x-nullable": true
            }
          },
          "x-nullable": true
        },
        "first_challenged_date": {
          "title": "First challenged date",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        },
        "related_incidents": {
          "description": "Array of incident IDs that are related through unclustering (both unclustered_to and unclustered_from)",
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "resolved_by": {
          "title": "Resolved by",
          "description": "Who classified the incident. Null when is_reclassified is true (use reclassified_by for that case).",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "resolved_on": {
          "title": "Resolved on",
          "description": "When the incident was classified. Null when is_reclassified is true (use reclassified_on for that case).",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        },
        "reclassified_by": {
          "title": "Reclassified by",
          "description": "Who reclassified this incident from another cluster. Only set when is_reclassified is true; null otherwise. Uses the same resolver source as resolved_by for non-reclassified incidents.",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "reclassified_on": {
          "title": "Reclassified on",
          "description": "When the incident was reclassified from another cluster. Only set when is_reclassified is true; null otherwise. Uses the same resolver source as resolved_on for non-reclassified incidents.",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        },
        "affected_mailboxes": {
          "description": "List of affected mailboxes (mitigations) for this incident",
          "type": "array",
          "items": {
            "$ref": "#/definitions/AffectedMailbox"
          }
        },
        "is_reclassified": {
          "title": "Is reclassified",
          "description": "Incident was created by reclassifying emails from another incident",
          "type": "boolean"
        },
        "original_cluster_incident_id": {
          "title": "Original cluster incident id",
          "description": "The ID of the original incident this was reclassified from (null if not reclassified)",
          "type": "integer",
          "x-nullable": true
        },
        "can_revert": {
          "title": "Can revert",
          "description": "Can be reverted to the original incident",
          "type": "boolean"
        },
        "revert_blocked_reason": {
          "title": "Revert blocked reason",
          "description": "Why revert is not possible (null if revert is possible)",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        }
      }
    },
    "IncidentList": {
      "required": [
        "incidentID",
        "emailSubject",
        "linksCount",
        "attachmentsCount",
        "recipientEmail",
        "recipientName",
        "classification",
        "assignee",
        "senderName",
        "senderEmail",
        "affectedMailboxesCount",
        "created",
        "reportedBy",
        "resolvedBy",
        "challengedType",
        "firstChallengedDate",
        "incidentType",
        "commentsCount",
        "releaseRequestCount",
        "latestEmailDate"
      ],
      "type": "object",
      "properties": {
        "incidentID": {
          "title": "Incidentid",
          "type": "integer"
        },
        "emailSubject": {
          "title": "Emailsubject",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "linksCount": {
          "title": "Linkscount",
          "type": "integer",
          "x-nullable": true
        },
        "attachmentsCount": {
          "title": "Attachmentscount",
          "type": "integer",
          "x-nullable": true
        },
        "recipientEmail": {
          "title": "Recipientemail",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "recipientName": {
          "title": "Recipientname",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "classification": {
          "title": "Classification",
          "type": "string",
          "minLength": 1
        },
        "assignee": {
          "title": "Assignee",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "senderName": {
          "title": "Sendername",
          "type": "string",
          "minLength": 1
        },
        "senderEmail": {
          "title": "Senderemail",
          "type": "string",
          "format": "email",
          "minLength": 1
        },
        "affectedMailboxesCount": {
          "title": "Affectedmailboxescount",
          "type": "integer"
        },
        "created": {
          "title": "Created",
          "type": "string",
          "format": "date-time"
        },
        "reportedBy": {
          "title": "Reportedby",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "resolvedBy": {
          "title": "Resolvedby",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "challengedType": {
          "title": "Challengedtype",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "firstChallengedDate": {
          "title": "Firstchallengeddate",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        },
        "incidentType": {
          "title": "Incidenttype",
          "type": "string",
          "minLength": 1
        },
        "commentsCount": {
          "title": "Commentscount",
          "type": "integer"
        },
        "releaseRequestCount": {
          "title": "Releaserequestcount",
          "type": "integer",
          "x-nullable": true
        },
        "latestEmailDate": {
          "title": "Latestemaildate",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        }
      }
    },
    "IncidentListPage": {
      "required": [
        "page",
        "total_pages",
        "total_count",
        "incidents"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "total_count": {
          "title": "Total count",
          "type": "integer"
        },
        "incidents": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/IncidentList"
          }
        }
      }
    },
    "ReclusterIncident": {
      "type": "object",
      "properties": {
        "mitigationsList": {
          "description": "List of mitigation IDs to move.",
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "excludeMitigations": {
          "description": "List of mitigation IDs to exclude when using the 'all' flag.",
          "type": "array",
          "items": {
            "type": "integer"
          },
          "default": []
        },
        "notFoundFilter": {
          "title": "Notfoundfilter",
          "description": "Filter mitigations that were not found in mailbox.",
          "type": "boolean",
          "default": false
        },
        "isReadFilter": {
          "title": "Isreadfilter",
          "description": "Filter mitigations by read status.",
          "type": "boolean",
          "x-nullable": true
        },
        "reclusterAll": {
          "title": "Reclusterall",
          "description": "If true, move all mitigations matching filters (uses incident_id from URL).",
          "type": "boolean",
          "default": false
        }
      }
    },
    "ScanBackList": {
      "required": [
        "incidentID",
        "emailSubject",
        "linksCount",
        "attachmentsCount",
        "recipientEmail",
        "recipientName",
        "classification",
        "assignee",
        "senderName",
        "senderEmail",
        "affectedMailboxesCount",
        "created",
        "reportedBy",
        "resolvedBy",
        "challengedType",
        "firstChallengedDate"
      ],
      "type": "object",
      "properties": {
        "incidentID": {
          "title": "Incidentid",
          "type": "integer"
        },
        "emailSubject": {
          "title": "Emailsubject",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "linksCount": {
          "title": "Linkscount",
          "type": "integer",
          "x-nullable": true
        },
        "attachmentsCount": {
          "title": "Attachmentscount",
          "type": "integer",
          "x-nullable": true
        },
        "recipientEmail": {
          "title": "Recipientemail",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "recipientName": {
          "title": "Recipientname",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "classification": {
          "title": "Classification",
          "type": "string",
          "minLength": 1
        },
        "assignee": {
          "title": "Assignee",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "senderName": {
          "title": "Sendername",
          "type": "string",
          "minLength": 1
        },
        "senderEmail": {
          "title": "Senderemail",
          "type": "string",
          "format": "email",
          "minLength": 1
        },
        "affectedMailboxesCount": {
          "title": "Affectedmailboxescount",
          "type": "integer"
        },
        "created": {
          "title": "Created",
          "type": "string",
          "format": "date-time"
        },
        "reportedBy": {
          "title": "Reportedby",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "resolvedBy": {
          "title": "Resolvedby",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "challengedType": {
          "title": "Challengedtype",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "firstChallengedDate": {
          "title": "Firstchallengeddate",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        }
      }
    },
    "ScanBackPage": {
      "required": [
        "page",
        "total_pages",
        "total_count",
        "incidents"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "total_count": {
          "title": "Total count",
          "type": "integer"
        },
        "incidents": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/ScanBackList"
          }
        }
      }
    },
    "RemediationStatusStats": {
      "required": [
        "incidents_count",
        "emails_count"
      ],
      "type": "object",
      "properties": {
        "incidents_count": {
          "title": "Incidents count",
          "type": "integer"
        },
        "emails_count": {
          "title": "Emails count",
          "type": "integer"
        }
      }
    },
    "RemediationStatusesStats": {
      "required": [
        "phishing",
        "spam",
        "safe",
        "unclassified"
      ],
      "type": "object",
      "properties": {
        "phishing": {
          "$ref": "#/definitions/RemediationStatusStats"
        },
        "spam": {
          "$ref": "#/definitions/RemediationStatusStats"
        },
        "safe": {
          "$ref": "#/definitions/RemediationStatusStats"
        },
        "unclassified": {
          "$ref": "#/definitions/RemediationStatusStats"
        }
      }
    },
    "UnclusterIncident": {
      "required": [
        "classification"
      ],
      "type": "object",
      "properties": {
        "mitigationsList": {
          "description": "List of mitigation IDs to move.",
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "excludeMitigations": {
          "description": "List of mitigation IDs to exclude when using the 'all' flag.",
          "type": "array",
          "items": {
            "type": "integer"
          },
          "default": []
        },
        "notFoundFilter": {
          "title": "Notfoundfilter",
          "description": "Filter mitigations that were not found in mailbox.",
          "type": "boolean",
          "default": false
        },
        "isReadFilter": {
          "title": "Isreadfilter",
          "description": "Filter mitigations by read status.",
          "type": "boolean",
          "x-nullable": true
        },
        "unclusterAll": {
          "title": "Unclusterall",
          "description": "If true, move all mitigations matching filters (uses incident_id from URL).",
          "type": "boolean",
          "default": false
        },
        "classification": {
          "title": "Classification",
          "description": "New classification for the unclustered incident. Must be one of: Attack, False Positive, Spam",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "AdminAuthorize": {
      "required": [
        "admin_consent",
        "state"
      ],
      "type": "object",
      "properties": {
        "admin_consent": {
          "title": "Admin consent",
          "type": "boolean"
        },
        "state": {
          "title": "State",
          "type": "string",
          "minLength": 1
        },
        "tenant": {
          "title": "Tenant",
          "type": "string",
          "minLength": 1
        },
        "error": {
          "title": "Error",
          "type": "string",
          "minLength": 1
        },
        "error_description": {
          "title": "Error description",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "AdminConsentResponse": {
      "required": [
        "oauth_full_url"
      ],
      "type": "object",
      "properties": {
        "oauth_full_url": {
          "title": "Oauth full url",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "AdminConsent": {
      "type": "object",
      "properties": {
        "azure_redirect_uri": {
          "title": "Azure redirect uri",
          "type": "string",
          "minLength": 1
        },
        "additional_data": {
          "title": "Additional data",
          "description": "\nNote: The custom_data field is limited to a maximum of 36 characters.\nOnly the following characters are allowed: letters (A-Z, a-z), digits (0-9), hyphen (-), and underscore (_).\nThis is sufficient to support UUIDs and other short identifiers.\n",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "MailboxesUserComplianceReport": {
      "required": [
        "firstName",
        "email"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "firstName": {
          "title": "First name",
          "type": "string",
          "maxLength": 40,
          "minLength": 1
        },
        "lastName": {
          "title": "Last name",
          "type": "string",
          "maxLength": 40,
          "x-nullable": true
        },
        "country": {
          "title": "Country",
          "type": "string",
          "maxLength": 100,
          "x-nullable": true
        },
        "department": {
          "title": "Department",
          "type": "string",
          "maxLength": 100,
          "x-nullable": true
        },
        "title": {
          "title": "Title",
          "type": "string",
          "maxLength": 250,
          "x-nullable": true
        },
        "email": {
          "title": "Email",
          "type": "string",
          "format": "email",
          "maxLength": 254,
          "minLength": 1
        },
        "language": {
          "title": "Language",
          "type": "string",
          "readOnly": true
        },
        "simulationCampaignsCompletionsCount": {
          "title": "Simulation campaigns completions count",
          "type": "integer",
          "readOnly": true
        },
        "lastSimulationCampaignDate": {
          "title": "Last simulation campaign date",
          "description": "date-time format %b %d, %Y %H:%M",
          "type": "string",
          "format": "date-time",
          "readOnly": true,
          "x-nullable": true
        },
        "trainingCampaignsCompletionsCount": {
          "title": "Training campaigns completions count",
          "type": "integer",
          "readOnly": true
        },
        "lastTrainingCampaignDate": {
          "title": "Last training campaign date",
          "description": "date-time format %b %d, %Y %H:%M",
          "type": "string",
          "format": "date-time",
          "readOnly": true,
          "x-nullable": true
        },
        "riskLevel": {
          "title": "Risk level",
          "type": "string",
          "enum": [
            "Low",
            "Medium",
            "High"
          ],
          "readOnly": true
        },
        "awarenessLevel": {
          "title": "Awareness level",
          "type": "string",
          "enum": [
            "Beginner Level",
            "Mid Level",
            "Expert Level"
          ],
          "readOnly": true
        }
      }
    },
    "MailboxesUserComplianceReportResponse": {
      "required": [
        "page",
        "total_pages",
        "data"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "data": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/MailboxesUserComplianceReport"
          }
        }
      }
    },
    "MailboxesDetails": {
      "required": [
        "id",
        "firstName",
        "lastName",
        "title",
        "department",
        "email",
        "phoneNumber",
        "tags",
        "language",
        "riskLevel",
        "awarenessLevel",
        "protected",
        "unprotectedReason"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "type": "integer"
        },
        "firstName": {
          "title": "Firstname",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "lastName": {
          "title": "Lastname",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "title": {
          "title": "Title",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "department": {
          "title": "Department",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "email": {
          "title": "Email",
          "type": "string",
          "minLength": 1
        },
        "phoneNumber": {
          "title": "Phonenumber",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "tags": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "x-nullable": true
        },
        "language": {
          "title": "Language",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "enabled": {
          "title": "Enabled",
          "type": "boolean"
        },
        "riskLevel": {
          "title": "Risklevel",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "awarenessLevel": {
          "title": "Awarenesslevel",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "protected": {
          "title": "Protected",
          "type": "boolean",
          "x-nullable": true
        },
        "unprotectedReason": {
          "title": "Unprotectedreason",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        }
      }
    },
    "MailboxesPageDetails": {
      "required": [
        "page",
        "total_pages",
        "total_count",
        "mailboxes"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "total_count": {
          "title": "Total count",
          "type": "integer"
        },
        "mailboxes": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/MailboxesDetails"
          }
        }
      }
    },
    "MailboxFilter": {
      "type": "object",
      "properties": {
        "ids": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "exclude_ids": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "search": {
          "title": "Search",
          "type": "string",
          "minLength": 1
        },
        "is_enabled": {
          "title": "Is enabled",
          "type": "boolean",
          "x-nullable": true
        },
        "tags": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        }
      }
    },
    "MailboxUpdateParams": {
      "type": "object",
      "properties": {
        "is_enabled": {
          "title": "Is enabled",
          "type": "boolean"
        },
        "add_tags": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        },
        "remove_tags": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        }
      }
    },
    "MailboxUpdateRequest": {
      "required": [
        "params"
      ],
      "type": "object",
      "properties": {
        "filters": {
          "$ref": "#/definitions/MailboxFilter"
        },
        "params": {
          "$ref": "#/definitions/MailboxUpdateParams"
        }
      }
    },
    "MailboxesUpdateResponse": {
      "required": [
        "mailbox_ids",
        "error_message"
      ],
      "type": "object",
      "properties": {
        "mailbox_ids": {
          "description": "IDs of mailboxes that matched the filters",
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "error_message": {
          "title": "Error message",
          "description": "Error description if any of mailboxes wasn't updated",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "MailboxesUserPerformance": {
      "required": [
        "userId",
        "firstName",
        "lastName",
        "country",
        "department",
        "title",
        "email",
        "campaignId",
        "campaignName",
        "campaignCollectingEndDate"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "userId": {
          "title": "Userid",
          "type": "integer"
        },
        "firstName": {
          "title": "First name",
          "type": "string",
          "minLength": 1
        },
        "lastName": {
          "title": "Last name",
          "type": "string",
          "minLength": 1
        },
        "country": {
          "title": "Country",
          "type": "string",
          "minLength": 1
        },
        "department": {
          "title": "Department",
          "type": "string",
          "minLength": 1
        },
        "title": {
          "title": "Title",
          "type": "string",
          "minLength": 1
        },
        "email": {
          "title": "Email",
          "type": "string",
          "minLength": 1
        },
        "campaignId": {
          "title": "Campaign id",
          "type": "integer"
        },
        "campaignName": {
          "title": "Campaign name",
          "type": "string",
          "minLength": 1
        },
        "campaignType": {
          "title": "Campaign type",
          "type": "string",
          "enum": [
            "Training",
            "Simulation",
            "Spear Phishing",
            "Agentic"
          ],
          "readOnly": true
        },
        "campaignSimulationResult": {
          "title": "Campaign simulation result",
          "type": "string",
          "enum": [
            "Reported",
            "Clicked",
            "Entered Details",
            "Opened",
            "Unopened",
            "Not delivered",
            "N/A"
          ],
          "readOnly": true,
          "x-nullable": true
        },
        "campaignTrainingStatus": {
          "title": "Campaign training status",
          "type": "string",
          "enum": [
            "Postponed",
            "Manually trained",
            "Yes",
            "No",
            "N/A",
            "Scheduled to send"
          ],
          "readOnly": true,
          "x-nullable": true
        },
        "campaignTrainingName": {
          "title": "Campaign training name",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "campaignCollectingEndDate": {
          "title": "Collecting end date (UTC)",
          "description": "date-time format %b %d, %Y %H:%M",
          "type": "string",
          "format": "date-time"
        },
        "campaignScore": {
          "title": "Campaign score",
          "type": "integer",
          "readOnly": true,
          "maximum": 100,
          "minimum": 0,
          "x-nullable": true
        },
        "campaignLocale": {
          "title": "Campaign locale",
          "type": "string",
          "readOnly": true
        },
        "campaignTemplateName": {
          "title": "Campaign template name",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        }
      }
    },
    "MailboxesUserPerformanceResponse": {
      "required": [
        "page",
        "total_pages",
        "data"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "data": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/MailboxesUserPerformance"
          }
        }
      }
    },
    "IncidentDetailsRequest": {
      "required": [
        "incidents"
      ],
      "type": "object",
      "properties": {
        "incidents": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "page": {
          "title": "Page",
          "type": "integer",
          "default": 1
        },
        "period": {
          "title": "Period",
          "type": "string",
          "default": "6",
          "minLength": 1
        }
      }
    },
    "MitigationDetails": {
      "required": [
        "incidentID",
        "mitigationID",
        "incidentState",
        "remediatedTime",
        "mailboxId",
        "mailboxEmail",
        "subject",
        "senderEmail",
        "senderIP",
        "reportedBy",
        "resolution",
        "spfResult"
      ],
      "type": "object",
      "properties": {
        "incidentID": {
          "title": "Incidentid",
          "type": "integer"
        },
        "mitigationID": {
          "title": "Mitigationid",
          "type": "integer"
        },
        "incidentState": {
          "title": "Incidentstate",
          "type": "string",
          "minLength": 1
        },
        "remediatedTime": {
          "title": "Remediatedtime",
          "type": "string",
          "format": "date-time"
        },
        "mailboxId": {
          "title": "Mailboxid",
          "type": "integer"
        },
        "mailboxEmail": {
          "title": "Mailboxemail",
          "type": "string",
          "minLength": 1
        },
        "subject": {
          "title": "Subject",
          "type": "string",
          "minLength": 1
        },
        "senderEmail": {
          "title": "Senderemail",
          "type": "string",
          "minLength": 1
        },
        "senderIP": {
          "title": "Senderip",
          "type": "string",
          "minLength": 1
        },
        "reportedBy": {
          "title": "Reportedby",
          "type": "string",
          "minLength": 1
        },
        "resolution": {
          "title": "Resolution",
          "type": "string",
          "minLength": 1
        },
        "spfResult": {
          "title": "Spfresult",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "MitigationPageDetails": {
      "required": [
        "page",
        "total_pages",
        "mitigations",
        "messages"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "mitigations": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/MitigationDetails"
          }
        },
        "messages": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        }
      }
    },
    "ImpersonationDetails": {
      "required": [
        "incidentID",
        "mailboxId",
        "remediatedTime",
        "mailboxEmail",
        "senderEmail",
        "subject",
        "reportedBy",
        "incidentType",
        "resolution",
        "remediations"
      ],
      "type": "object",
      "properties": {
        "incidentID": {
          "title": "Incidentid",
          "type": "integer"
        },
        "mailboxId": {
          "title": "Mailboxid",
          "type": "integer"
        },
        "remediatedTime": {
          "title": "Remediatedtime",
          "type": "string",
          "format": "date-time"
        },
        "mailboxEmail": {
          "title": "Mailboxemail",
          "type": "string",
          "format": "email",
          "minLength": 1
        },
        "senderEmail": {
          "title": "Senderemail",
          "type": "string",
          "format": "email",
          "minLength": 1
        },
        "subject": {
          "title": "Subject",
          "type": "string",
          "minLength": 1
        },
        "reportedBy": {
          "title": "Reportedby",
          "type": "string",
          "format": "email",
          "minLength": 1
        },
        "incidentType": {
          "title": "Incidenttype",
          "type": "string",
          "minLength": 1
        },
        "resolution": {
          "title": "Resolution",
          "type": "string",
          "minLength": 1
        },
        "remediations": {
          "title": "Remediations",
          "type": "integer"
        }
      }
    },
    "ImpersonationDetailsPage": {
      "required": [
        "incidents",
        "messages"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer",
          "x-nullable": true
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer",
          "x-nullable": true
        },
        "incidents": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/ImpersonationDetails"
          }
        },
        "messages": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        }
      }
    },
    "ImpersonationDetailsRequest": {
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer",
          "default": 1
        },
        "period": {
          "title": "Period",
          "type": "string",
          "default": "6",
          "minLength": 1
        }
      }
    },
    "MitigationIncidentDetails": {
      "required": [
        "incidentID",
        "incidentState",
        "remediatedTime",
        "affectedMailboxCount",
        "mailboxId",
        "mailboxEmail",
        "senderEmail",
        "subject",
        "threatType",
        "detectionType",
        "reportedBy"
      ],
      "type": "object",
      "properties": {
        "incidentID": {
          "title": "Incidentid",
          "type": "integer"
        },
        "incidentState": {
          "title": "Incidentstate",
          "type": "integer"
        },
        "remediatedTime": {
          "title": "Remediatedtime",
          "type": "string",
          "format": "date-time"
        },
        "affectedMailboxCount": {
          "title": "Affectedmailboxcount",
          "type": "integer"
        },
        "mailboxId": {
          "title": "Mailboxid",
          "type": "integer"
        },
        "mailboxEmail": {
          "title": "Mailboxemail",
          "type": "string",
          "format": "email",
          "minLength": 1
        },
        "senderEmail": {
          "title": "Senderemail",
          "type": "string",
          "format": "email",
          "minLength": 1
        },
        "subject": {
          "title": "Subject",
          "type": "string",
          "minLength": 1
        },
        "threatType": {
          "title": "Threattype",
          "type": "string",
          "minLength": 1
        },
        "detectionType": {
          "title": "Detectiontype",
          "type": "string",
          "minLength": 1
        },
        "reportedBy": {
          "title": "Reportedby",
          "type": "string",
          "format": "email",
          "minLength": 1
        }
      }
    },
    "IncidentPageDetails": {
      "required": [
        "page",
        "total_pages",
        "incidents",
        "messages"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "incidents": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/MitigationIncidentDetails"
          }
        },
        "messages": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        }
      }
    },
    "MitigationStats": {
      "required": [
        "openIncidentCount",
        "resolvedIncidentCount",
        "phishingCount",
        "remediationCount",
        "maliciousAttachmentsCount",
        "maliciousLinksCount",
        "impersonationCount",
        "reportedByEmployeesCount"
      ],
      "type": "object",
      "properties": {
        "openIncidentCount": {
          "title": "Openincidentcount",
          "type": "integer"
        },
        "resolvedIncidentCount": {
          "title": "Resolvedincidentcount",
          "type": "integer"
        },
        "phishingCount": {
          "title": "Phishingcount",
          "type": "integer"
        },
        "remediationCount": {
          "title": "Remediationcount",
          "type": "integer"
        },
        "maliciousAttachmentsCount": {
          "title": "Maliciousattachmentscount",
          "type": "integer"
        },
        "maliciousLinksCount": {
          "title": "Maliciouslinkscount",
          "type": "integer"
        },
        "impersonationCount": {
          "title": "Impersonationcount",
          "type": "integer"
        },
        "reportedByEmployeesCount": {
          "title": "Reportedbyemployeescount",
          "type": "integer"
        }
      }
    },
    "EmailPhishingThreatTypeStats": {
      "required": [
        "name",
        "emails_count"
      ],
      "type": "object",
      "properties": {
        "name": {
          "title": "Name",
          "type": "string",
          "minLength": 1
        },
        "emails_count": {
          "title": "Emails count",
          "type": "integer"
        }
      }
    },
    "EmailsStats": {
      "required": [
        "inspected_count",
        "phishing_count",
        "spam_count",
        "impersonations_count",
        "phishing_threat_types"
      ],
      "type": "object",
      "properties": {
        "inspected_count": {
          "title": "Inspected count",
          "type": "integer"
        },
        "phishing_count": {
          "title": "Phishing count",
          "type": "integer"
        },
        "spam_count": {
          "title": "Spam count",
          "type": "integer"
        },
        "impersonations_count": {
          "title": "Impersonations count",
          "type": "integer"
        },
        "phishing_threat_types": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/EmailPhishingThreatTypeStats"
          }
        }
      }
    },
    "MostTargetedDepartment": {
      "required": [
        "name",
        "emails_count"
      ],
      "type": "object",
      "properties": {
        "name": {
          "title": "Name",
          "type": "string",
          "minLength": 1
        },
        "emails_count": {
          "title": "Emails count",
          "type": "integer"
        }
      }
    },
    "MostTargetedDepartments": {
      "required": [
        "items"
      ],
      "type": "object",
      "properties": {
        "items": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/MostTargetedDepartment"
          }
        }
      }
    },
    "MostTargetedEmployee": {
      "type": "object",
      "properties": {
        "mailbox": {
          "$ref": "#/definitions/MailboxesDetails"
        },
        "emails_count": {
          "title": "Emails count",
          "type": "integer",
          "readOnly": true
        }
      }
    },
    "MostTargetedEmployees": {
      "required": [
        "items"
      ],
      "type": "object",
      "properties": {
        "items": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/MostTargetedEmployee"
          }
        }
      }
    },
    "ResolvedByAnalyst": {
      "type": "object",
      "properties": {
        "time_saved": {
          "title": "Time saved",
          "type": "number",
          "x-nullable": true
        },
        "from_users": {
          "title": "From users",
          "type": "integer",
          "x-nullable": true
        },
        "from_community": {
          "title": "From community",
          "type": "integer",
          "x-nullable": true
        },
        "from_mailbox_anomaly": {
          "title": "From mailbox anomaly",
          "type": "integer",
          "x-nullable": true
        },
        "avg_resolution_time": {
          "title": "Avg resolution time",
          "type": "number",
          "x-nullable": true
        },
        "total": {
          "title": "Total",
          "type": "integer",
          "x-nullable": true
        }
      }
    },
    "InspectedEmails": {
      "required": [
        "phishing",
        "false_positive",
        "incidents",
        "inspected",
        "spam"
      ],
      "type": "object",
      "properties": {
        "phishing": {
          "title": "Phishing",
          "type": "integer",
          "x-nullable": true
        },
        "false_positive": {
          "title": "False positive",
          "type": "integer",
          "x-nullable": true
        },
        "incidents": {
          "title": "Incidents",
          "type": "integer",
          "x-nullable": true
        },
        "inspected": {
          "title": "Inspected",
          "type": "integer",
          "x-nullable": true
        },
        "spam": {
          "title": "Spam",
          "type": "integer",
          "x-nullable": true
        }
      }
    },
    "ResolvedAutomatically": {
      "required": [
        "time_saved",
        "from_users",
        "from_community",
        "from_mailbox_anomaly",
        "by_visual_scanner",
        "total",
        "by_malware_and_url_scanners",
        "by_themis"
      ],
      "type": "object",
      "properties": {
        "time_saved": {
          "title": "Time saved",
          "type": "number",
          "x-nullable": true
        },
        "from_users": {
          "title": "From users",
          "type": "integer",
          "x-nullable": true
        },
        "from_community": {
          "title": "From community",
          "type": "integer",
          "x-nullable": true
        },
        "from_mailbox_anomaly": {
          "title": "From mailbox anomaly",
          "type": "integer",
          "x-nullable": true
        },
        "by_visual_scanner": {
          "title": "By visual scanner",
          "type": "integer",
          "x-nullable": true
        },
        "total": {
          "title": "Total",
          "type": "integer",
          "x-nullable": true
        },
        "by_malware_and_url_scanners": {
          "title": "By malware and url scanners",
          "type": "integer",
          "x-nullable": true
        },
        "by_themis": {
          "title": "By themis",
          "type": "integer",
          "x-nullable": true
        }
      }
    },
    "MaliciousContentIncidents": {
      "required": [
        "computer_vision",
        "total_malicious_incidents",
        "attachments",
        "malware_and_url_protection"
      ],
      "type": "object",
      "properties": {
        "computer_vision": {
          "title": "Computer vision",
          "type": "integer",
          "x-nullable": true
        },
        "total_malicious_incidents": {
          "title": "Total malicious incidents",
          "type": "integer",
          "x-nullable": true
        },
        "attachments": {
          "title": "Attachments",
          "type": "integer",
          "x-nullable": true
        },
        "malware_and_url_protection": {
          "title": "Malware and url protection",
          "type": "integer",
          "x-nullable": true
        }
      }
    },
    "MitigationStatsV2View": {
      "type": "object",
      "properties": {
        "resolved_by_analyst": {
          "$ref": "#/definitions/ResolvedByAnalyst"
        },
        "inspected_emails": {
          "$ref": "#/definitions/InspectedEmails"
        },
        "resolved_automatically": {
          "$ref": "#/definitions/ResolvedAutomatically"
        },
        "malicious_content_incidents": {
          "$ref": "#/definitions/MaliciousContentIncidents"
        }
      }
    },
    "CompanyChoice": {
      "description": "List of companies that can acquire the migrating company",
      "required": [
        "id",
        "name"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "type": "integer"
        },
        "name": {
          "title": "Name",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "PossibleAcquiringCompaniesResponse": {
      "required": [
        "total_pages",
        "total_items",
        "page",
        "possible_acquiring_companies"
      ],
      "type": "object",
      "properties": {
        "total_pages": {
          "title": "Total pages",
          "description": "Total number of pages available",
          "type": "integer"
        },
        "total_items": {
          "title": "Total items",
          "description": "Total number of companies available",
          "type": "integer"
        },
        "page": {
          "title": "Page",
          "description": "Current page number",
          "type": "integer"
        },
        "possible_acquiring_companies": {
          "description": "List of companies that can acquire the migrating company",
          "type": "array",
          "items": {
            "$ref": "#/definitions/CompanyChoice"
          }
        }
      }
    },
    "PartnerMigrationRequest": {
      "required": [
        "migrating_company_id",
        "acquiring_company_id"
      ],
      "type": "object",
      "properties": {
        "migrating_company_id": {
          "title": "Migrating company id",
          "description": "ID of the company to migrate (must be managed by an MSP)",
          "type": "integer"
        },
        "acquiring_company_id": {
          "title": "Acquiring company id",
          "description": "ID of the MSP company that will acquire the migrating company",
          "type": "integer"
        }
      }
    },
    "CreatePartner": {
      "required": [
        "name",
        "ownerEmail",
        "ownerFirstName",
        "ownerLastName",
        "domain"
      ],
      "type": "object",
      "properties": {
        "name": {
          "title": "Name",
          "type": "string",
          "maxLength": 100,
          "minLength": 1
        },
        "ownerEmail": {
          "title": "Owneremail",
          "type": "string",
          "maxLength": 75,
          "minLength": 1
        },
        "ownerFirstName": {
          "title": "Ownerfirstname",
          "type": "string",
          "maxLength": 30,
          "minLength": 1
        },
        "ownerLastName": {
          "title": "Ownerlastname",
          "type": "string",
          "maxLength": 30,
          "minLength": 1
        },
        "domain": {
          "title": "Domain",
          "type": "string",
          "maxLength": 50,
          "minLength": 1
        },
        "partner_id": {
          "title": "Partner id",
          "type": "string",
          "default": "me",
          "minLength": 1
        },
        "allowedDomains": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        },
        "country": {
          "title": "Country",
          "description": "ISO 3166 country name",
          "type": "string",
          "minLength": 1
        },
        "autopilotEnabled": {
          "title": "Autopilotenabled",
          "type": "boolean"
        },
        "supportEmail": {
          "title": "Supportemail",
          "type": "string",
          "maxLength": 100,
          "minLength": 1
        },
        "supportPhone": {
          "title": "Supportphone",
          "type": "string",
          "maxLength": 100,
          "minLength": 1
        },
        "logoFile": {
          "title": "Logofile",
          "type": "string",
          "format": "uri",
          "maxLength": 250,
          "minLength": 1
        },
        "planType": {
          "title": "Plantype",
          "description": "<ul><li>3 - Core</li><li>4 - Email Protect</li><li>5 - Complete Protect</li><li>6 - IRONSCALES Protect</li></ul>",
          "type": "integer",
          "enum": [
            3,
            4,
            5,
            6
          ]
        },
        "isTrial": {
          "title": "Istrial",
          "type": "boolean",
          "default": false
        },
        "mailboxLimit": {
          "title": "Mailboxlimit",
          "description": "Employee/Mailboxes count limit",
          "type": "integer"
        }
      }
    },
    "GetPartnerFeature": {
      "type": "object",
      "properties": {
        "addCompanyOption": {
          "title": "Addcompanyoption",
          "type": "boolean"
        },
        "editMspDashboard": {
          "title": "Editmspdashboard",
          "type": "boolean"
        },
        "enforceMailboxLimit": {
          "title": "Enforcemailboxlimit",
          "type": "boolean"
        },
        "autopilotEnabled": {
          "title": "Autopilotenabled",
          "type": "boolean"
        }
      }
    },
    "UpdatePartnerFeature": {
      "required": [
        "feature",
        "state"
      ],
      "type": "object",
      "properties": {
        "feature": {
          "title": "Feature",
          "type": "string",
          "maxLength": 100,
          "minLength": 1
        },
        "state": {
          "title": "State",
          "type": "string",
          "maxLength": 75,
          "minLength": 1
        }
      }
    },
    "PlanDetails": {
      "required": [
        "id"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "type": "integer"
        },
        "trialExpiration": {
          "title": "Trialexpiration",
          "type": "string",
          "format": "date-time"
        },
        "trialPlanType": {
          "title": "Trialplantype",
          "type": "string",
          "readOnly": true
        },
        "premiumContentType": {
          "title": "Premiumcontenttype",
          "type": "string",
          "readOnly": true
        },
        "planType": {
          "title": "Plantype",
          "type": "string",
          "readOnly": true
        },
        "planExpiration": {
          "title": "Planexpiration",
          "type": "string",
          "format": "date-time"
        },
        "mailboxLimit": {
          "title": "Mailboxlimit",
          "description": "Employee/Mailboxes count limit",
          "type": "integer"
        },
        "is_partner": {
          "title": "Is partner",
          "type": "boolean"
        },
        "testMode": {
          "title": "Testmode",
          "type": "boolean"
        }
      }
    },
    "PlansDetails": {
      "required": [
        "licenses"
      ],
      "type": "object",
      "properties": {
        "licenses": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/PlanDetails"
          }
        }
      }
    },
    "PartnerCompanyUsageReportMonthlyRequest": {
      "required": [
        "year",
        "month"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer",
          "default": 1
        },
        "plan_active": {
          "title": "Plan active",
          "type": "boolean"
        },
        "trial_active": {
          "title": "Trial active",
          "type": "boolean"
        },
        "year": {
          "title": "Year",
          "type": "integer"
        },
        "month": {
          "title": "Month",
          "type": "integer",
          "maximum": 12,
          "minimum": 1
        }
      }
    },
    "PartnerCompanyUsageReportMonthly": {
      "required": [
        "sync_date",
        "billing_date",
        "company_id",
        "billable_mailboxes",
        "plan_id",
        "plan_expiration_date",
        "registration_date"
      ],
      "type": "object",
      "properties": {
        "sync_date": {
          "title": "Sync date",
          "type": "string",
          "format": "date"
        },
        "billing_date": {
          "title": "Billing date",
          "type": "string",
          "format": "date"
        },
        "company_id": {
          "title": "Company id",
          "type": "integer"
        },
        "company_name": {
          "title": "Company name",
          "type": "string",
          "minLength": 1
        },
        "partner_id": {
          "title": "Partner id",
          "type": "integer"
        },
        "partner_name": {
          "title": "Partner name",
          "type": "string",
          "minLength": 1
        },
        "billable_mailboxes": {
          "title": "Billable mailboxes",
          "type": "integer"
        },
        "plan_id": {
          "title": "Plan id",
          "type": "integer"
        },
        "plan_name": {
          "title": "Plan name",
          "type": "string",
          "readOnly": true
        },
        "active_addons": {
          "title": "Active addons",
          "type": "object",
          "readOnly": true,
          "properties": {
            "DMARC_DOMAINS": {
              "type": "integer"
            },
            "SAT_CONTENT_PACK_NAME": {
              "type": "string"
            }
          },
          "additionalProperties": {
            "type": "boolean"
          },
          "example": {
            "ADDON_NAME": false,
            "ANOTHER_ADDON_NAME": true
          }
        },
        "billable_items": {
          "title": "Billable items",
          "description": "Enabled addons that are not included in company plan. Object represents enabled addons and associated quantity (see response example)",
          "type": "object",
          "readOnly": true,
          "example": {
            "ADDON_NAME": true,
            "ADDON_NAME_QUANTITY": 1,
            "ANOTHER_ADDON_NAME": true,
            "ANOTHER_ADDON_NAME_QUANTITY": 2
          }
        },
        "plan_expiration_date": {
          "title": "Plan expiration date",
          "type": "string",
          "format": "date"
        },
        "trial_expiration_date": {
          "title": "Trial expiration date",
          "type": "string",
          "format": "date"
        },
        "registration_date": {
          "title": "Registration date",
          "type": "string",
          "format": "date"
        },
        "is_partner": {
          "title": "Is partner",
          "type": "boolean",
          "x-nullable": true
        }
      }
    },
    "PartnerCompanyUsageReportMonthlyResponse": {
      "required": [
        "total_pages",
        "page",
        "data"
      ],
      "type": "object",
      "properties": {
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "data": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/PartnerCompanyUsageReportMonthly"
          }
        }
      }
    },
    "AllowedDomains": {
      "required": [
        "domains"
      ],
      "type": "object",
      "properties": {
        "domains": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        }
      }
    },
    "PlanSetOrUpdate": {
      "type": "object",
      "properties": {
        "planType": {
          "title": "Plantype",
          "description": "Plan selection is limited to the options defined in your contract",
          "type": "integer",
          "enum": [
            1,
            2,
            3,
            4,
            5,
            6,
            7
          ]
        },
        "planExpiration": {
          "title": "Planexpiration",
          "description": "expiration date",
          "type": "string",
          "format": "date-time"
        },
        "trialPlanType": {
          "title": "Trialplantype",
          "description": "Trial plan selection is limited to the options defined in your contract",
          "type": "integer",
          "enum": [
            6,
            3,
            4,
            5,
            7
          ]
        },
        "trialExpiration": {
          "title": "Trialexpiration",
          "description": "Premium content type",
          "type": "string",
          "format": "date-time"
        },
        "premiumContentType": {
          "title": "Premiumcontenttype",
          "description": "Enable or disable premium content",
          "type": "integer",
          "enum": [
            1,
            3,
            4
          ]
        },
        "mailboxLimit": {
          "title": "Mailboxlimit",
          "description": "Employee/Mailboxes count limit",
          "type": "integer"
        },
        "testMode": {
          "title": "Testmode",
          "type": "boolean"
        }
      }
    },
    "CancelPlan": {
      "required": [
        "licenses"
      ],
      "type": "object",
      "properties": {
        "licenses": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          }
        }
      }
    },
    "CampaignStatistic": {
      "required": [
        "emails",
        "reported",
        "lured",
        "trained"
      ],
      "type": "object",
      "properties": {
        "emails": {
          "title": "Emails",
          "type": "integer",
          "x-nullable": true
        },
        "reported": {
          "title": "Reported",
          "type": "integer",
          "x-nullable": true
        },
        "lured": {
          "title": "Lured",
          "type": "integer",
          "x-nullable": true
        },
        "trained": {
          "title": "Trained",
          "type": "integer",
          "x-nullable": true
        }
      }
    },
    "CampaignListResponseItem": {
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "name": {
          "title": "Name",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "flow_type": {
          "title": "Flow type",
          "description": "Campaign Flow Type:\n- `1` = Training Only - Campaign that only includes training content\n- `2` = Simulation and Training - Campaign that includes both phishing simulation and training",
          "type": "string",
          "enum": [
            1,
            2
          ],
          "readOnly": true
        },
        "status": {
          "title": "Status",
          "description": "Campaign Status:\n- `0` = Draft - Campaign is in draft state and not yet active\n- `1` = Collecting (Active) - Campaign is actively collecting participant data\n- `2` = Completed - Campaign has finished and is closed\n- `3` = Pending - Campaign is approved but waiting to start\n- `4` = Active - Campaign is currently running and sending emails\n- `5` = Inactive - Campaign is inactive",
          "type": "string",
          "enum": [
            0,
            1,
            2,
            3,
            4,
            5
          ],
          "readOnly": true
        },
        "schedule_time": {
          "title": "Schedule time",
          "type": "string",
          "format": "date-time",
          "readOnly": true
        },
        "end_time": {
          "title": "End time",
          "type": "string",
          "format": "date-time",
          "readOnly": true
        },
        "close_time": {
          "title": "Close time",
          "type": "string",
          "format": "date-time",
          "readOnly": true
        },
        "default_locale_id": {
          "title": "Default locale id",
          "type": "integer",
          "readOnly": true
        },
        "timezone": {
          "title": "Timezone",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "participants_count": {
          "title": "Participants count",
          "type": "integer",
          "readOnly": true
        },
        "statistic": {
          "$ref": "#/definitions/CampaignStatistic"
        }
      }
    },
    "CampaignListResponse": {
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer",
          "readOnly": true
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer",
          "readOnly": true
        },
        "total_count": {
          "title": "Total count",
          "type": "integer",
          "readOnly": true
        },
        "data": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/CampaignListResponseItem"
          },
          "readOnly": true
        }
      }
    },
    "ParticipantsCalculateInclude": {
      "description": "Participant selection criteria",
      "required": [
        "all_company"
      ],
      "type": "object",
      "properties": {
        "emails": {
          "type": "array",
          "items": {
            "type": "string",
            "format": "email",
            "minLength": 1
          },
          "minItems": 1
        },
        "departments": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "tags": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "titles": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "cities": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "countries": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "featured_groups": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "segments": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "awareness_levels": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "all_company": {
          "title": "All company",
          "type": "boolean"
        }
      }
    },
    "ParticipantsCalculateBase": {
      "description": "Participant exclusion criteria",
      "type": "object",
      "properties": {
        "emails": {
          "type": "array",
          "items": {
            "type": "string",
            "format": "email",
            "minLength": 1
          },
          "minItems": 1
        },
        "departments": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "tags": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "titles": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "cities": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "countries": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "featured_groups": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "segments": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        },
        "awareness_levels": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "minItems": 1
        }
      },
      "x-nullable": true
    },
    "TrainingReminderContent": {
      "description": "List of training reminder content",
      "required": [
        "body",
        "subject"
      ],
      "type": "object",
      "properties": {
        "body": {
          "title": "Body",
          "type": "string",
          "minLength": 1
        },
        "subject": {
          "title": "Subject",
          "type": "string",
          "minLength": 1
        }
      },
      "x-nullable": true
    },
    "CampaignNotification": {
      "description": "List of campaign notifications",
      "required": [
        "type"
      ],
      "type": "object",
      "properties": {
        "subject": {
          "title": "Subject",
          "type": "string"
        },
        "body": {
          "title": "Body",
          "type": "string"
        },
        "type": {
          "title": "Type",
          "type": "integer",
          "enum": [
            1
          ]
        }
      },
      "x-nullable": true
    },
    "TrainingCampaignData": {
      "description": "Training-specific campaign data",
      "type": "object",
      "properties": {
        "subject": {
          "title": "Subject",
          "type": "string",
          "maxLength": 300,
          "x-nullable": true
        },
        "message": {
          "title": "Message",
          "type": "string",
          "x-nullable": true
        },
        "mail_signature": {
          "title": "Mail signature",
          "type": "string",
          "x-nullable": true
        },
        "include_logo": {
          "title": "Include logo",
          "type": "boolean",
          "x-nullable": true
        },
        "use_designed_image": {
          "title": "Use designed image",
          "type": "boolean",
          "x-nullable": true
        },
        "from_email": {
          "title": "From email",
          "type": "string",
          "maxLength": 512,
          "x-nullable": true
        }
      },
      "x-nullable": true
    },
    "ManagerNotificationBanner": {
      "description": "Manager notification banner settings",
      "required": [
        "text"
      ],
      "type": "object",
      "properties": {
        "text": {
          "title": "Text",
          "type": "string",
          "minLength": 1
        }
      },
      "x-nullable": true
    },
    "ManagerReportEmail": {
      "description": "Manager report email settings",
      "required": [
        "body",
        "subject"
      ],
      "type": "object",
      "properties": {
        "body": {
          "title": "Body",
          "type": "string",
          "minLength": 1
        },
        "subject": {
          "title": "Subject",
          "type": "string",
          "minLength": 1
        }
      },
      "x-nullable": true
    },
    "ManagerNotificationSettingsCreate": {
      "description": "Manager notification settings. If enabled is False or missing, manager notifications will not be configured.",
      "type": "object",
      "properties": {
        "enabled": {
          "title": "Enabled",
          "description": "Whether manager notifications are enabled for this campaign",
          "type": "boolean",
          "default": false
        },
        "banner": {
          "$ref": "#/definitions/ManagerNotificationBanner"
        },
        "report_email": {
          "$ref": "#/definitions/ManagerReportEmail"
        },
        "reminders_threshold": {
          "title": "Reminders threshold",
          "description": "Minimum number of reminders before sending manager report",
          "type": "integer",
          "minimum": 1,
          "x-nullable": true
        },
        "send_report_every_x_days": {
          "title": "Send report every x days",
          "description": "Send manager report every X days. Allowed values: 7 or 14 days",
          "type": "integer",
          "enum": [
            7,
            14
          ],
          "x-nullable": true
        },
        "report_day_of_week": {
          "title": "Report day of week",
          "description": "Day of week to send manager report (0=Monday, 6=Sunday)",
          "type": "integer",
          "maximum": 6,
          "minimum": 0,
          "x-nullable": true
        }
      },
      "x-nullable": true
    },
    "CampaignCreateRequest": {
      "required": [
        "name",
        "flow_type",
        "schedule_time",
        "close_time",
        "default_locale_id",
        "participants_choices"
      ],
      "type": "object",
      "properties": {
        "name": {
          "title": "Name",
          "description": "Campaign name",
          "type": "string",
          "maxLength": 250,
          "minLength": 1
        },
        "flow_type": {
          "title": "Flow type",
          "description": "Campaign Flow Type:\n- `1` = Training Only - Campaign that only includes training content\n- `2` = Simulation and Training - Campaign that includes both phishing simulation and training",
          "type": "integer",
          "enum": [
            1,
            2
          ]
        },
        "schedule_time": {
          "title": "Schedule time",
          "description": "Campaign start time in ISO 8601 format",
          "type": "string",
          "format": "date-time"
        },
        "close_time": {
          "title": "Close time",
          "description": "Campaign close time in ISO 8601 format",
          "type": "string",
          "format": "date-time"
        },
        "default_locale_id": {
          "title": "Default locale id",
          "description": "Default locale ID for the campaign",
          "type": "integer"
        },
        "participants_choices": {
          "$ref": "#/definitions/ParticipantsCalculateInclude"
        },
        "end_date": {
          "title": "End date",
          "description": "Campaign end date (for simulation campaigns)",
          "type": "string",
          "format": "date",
          "x-nullable": true
        },
        "timezone": {
          "title": "Timezone",
          "description": "Timezone string (e.g., 'America/New_York'). Defaults to company timezone if not provided",
          "type": "string"
        },
        "selected_locale_ids": {
          "description": "List of additional locale IDs for the campaign",
          "type": "array",
          "items": {
            "type": "integer"
          },
          "default": []
        },
        "email_limit": {
          "title": "Email limit",
          "description": "Maximum number of emails to send per day. Maximum allowed value is 20000. Use 0 for no limit.",
          "type": "integer",
          "default": 0,
          "maximum": 20000,
          "minimum": 0
        },
        "randomized": {
          "title": "Randomized",
          "description": "Send emails to participants at random times",
          "type": "boolean",
          "default": false
        },
        "randomized_scenarios": {
          "title": "Randomized scenarios",
          "description": "Randomize scenario selection for participants",
          "type": "boolean",
          "default": false
        },
        "send_all_week": {
          "title": "Send all week",
          "description": "Send emails throughout the week (including weekends)",
          "type": "boolean",
          "default": false
        },
        "locales_by_profiles": {
          "title": "Locales by profiles",
          "description": "Use locale settings from individual profiles",
          "type": "boolean",
          "default": false
        },
        "participants_exclude_choices": {
          "$ref": "#/definitions/ParticipantsCalculateBase"
        },
        "participants_exclude_choices_auto_fill": {
          "title": "Participants exclude choices auto fill",
          "description": "Automatically exclude shared mailboxes if they exist",
          "type": "boolean",
          "default": false
        },
        "scenario_ids": {
          "description": "List of scenario (mail template) IDs to use",
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "landing_page_id": {
          "title": "Landing page id",
          "description": "Landing page ID for the campaign",
          "type": "integer",
          "x-nullable": true
        },
        "training_ids": {
          "description": "List of training content IDs to include",
          "type": "array",
          "items": {
            "type": "integer"
          },
          "x-nullable": true
        },
        "send_reminder_every_x_business_days": {
          "title": "Send reminder every x business days",
          "description": "Send reminder every X business days",
          "type": "integer",
          "default": 2,
          "minimum": 1,
          "x-nullable": true
        },
        "send_reminders_until": {
          "title": "Send reminders until",
          "description": "Stop sending reminders after this date/time",
          "type": "string",
          "format": "date-time",
          "x-nullable": true
        },
        "max_reminders_per_participant": {
          "title": "Max reminders per participant",
          "description": "Maximum number of reminders per participant",
          "type": "integer",
          "minimum": 1,
          "x-nullable": true
        },
        "training_reminders": {
          "description": "List of training reminder content",
          "type": "array",
          "items": {
            "$ref": "#/definitions/TrainingReminderContent"
          },
          "x-nullable": true
        },
        "notifications": {
          "description": "List of campaign notifications",
          "type": "array",
          "items": {
            "$ref": "#/definitions/CampaignNotification"
          },
          "x-nullable": true
        },
        "send_campaign_summary_to_campaign_report_recipients": {
          "title": "Send campaign summary to campaign report recipients",
          "description": "Send campaign summary to report recipients",
          "type": "boolean",
          "default": true
        },
        "send_completion_email": {
          "title": "Send completion email",
          "description": "Send completion email to participants",
          "type": "boolean",
          "default": false
        },
        "send_campaign_failed_email": {
          "title": "Send campaign failed email",
          "description": "Send email notification if campaign fails",
          "type": "boolean",
          "default": false
        },
        "training_campaign_data": {
          "$ref": "#/definitions/TrainingCampaignData"
        },
        "manager_notification_settings": {
          "$ref": "#/definitions/ManagerNotificationSettingsCreate"
        }
      }
    },
    "CampaignCreateResponse": {
      "required": [
        "id"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "description": "Created campaign ID",
          "type": "integer"
        }
      }
    },
    "LandingPage": {
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "name": {
          "title": "Name",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "is_system": {
          "title": "Is system",
          "type": "boolean",
          "readOnly": true
        }
      },
      "x-nullable": true
    },
    "Segment": {
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "name": {
          "title": "Name",
          "type": "string",
          "readOnly": true,
          "maxLength": 120,
          "minLength": 1
        }
      }
    },
    "Category": {
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "name": {
          "title": "Name",
          "type": "string",
          "readOnly": true,
          "maxLength": 50,
          "minLength": 1
        }
      }
    },
    "Scenario": {
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "name": {
          "title": "Name",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "category": {
          "$ref": "#/definitions/Category"
        },
        "level": {
          "title": "Level",
          "type": "integer",
          "enum": [
            0,
            1,
            2
          ],
          "readOnly": true
        },
        "is_system": {
          "title": "Is system",
          "type": "boolean",
          "readOnly": true
        }
      }
    },
    "CampaignTrainingContentItem": {
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "locale_id": {
          "title": "Locale id",
          "type": "string",
          "readOnly": true
        },
        "image_preview": {
          "title": "Image preview",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "content": {
          "title": "Content",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "embedded_subtitles": {
          "title": "Embedded subtitles",
          "type": "boolean",
          "readOnly": true
        },
        "custom_type": {
          "title": "Custom type",
          "type": "string",
          "enum": [
            "CUSTOM_VIDEO",
            "CUSTOM_URL"
          ],
          "readOnly": true
        }
      }
    },
    "BaseTrainingSubtitle": {
      "type": "object",
      "properties": {
        "locale_id": {
          "title": "Locale id",
          "type": "integer",
          "readOnly": true
        },
        "url": {
          "title": "Url",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        }
      }
    },
    "CampaignTrainingContent": {
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "vendor": {
          "title": "Vendor",
          "type": "integer",
          "enum": [
            6,
            5,
            1,
            3,
            4
          ],
          "readOnly": true,
          "x-nullable": true
        },
        "name": {
          "title": "Name",
          "type": "string",
          "readOnly": true
        },
        "items": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/CampaignTrainingContentItem"
          },
          "readOnly": true
        },
        "type": {
          "title": "Type",
          "type": "string",
          "enum": [
            "VIDEO",
            "COURSE",
            "QUIZ_HTML5",
            "CUSTOM_CONTENT"
          ],
          "readOnly": true
        },
        "subtitles": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/BaseTrainingSubtitle"
          },
          "readOnly": true
        }
      }
    },
    "CampaignManagerNotificationSettings": {
      "type": "object",
      "properties": {
        "enabled": {
          "title": "Enabled",
          "description": "Get enabled status for manager notifications.\n\n        Args:\n            obj: ManagerNotificationSettings instance.\n\n        Returns:\n            True if send_report_every_x_days is not 0 or None, False otherwise.\n",
          "type": "boolean",
          "readOnly": true
        },
        "reminders_threshold": {
          "title": "Reminders threshold",
          "type": "integer",
          "readOnly": true,
          "minimum": 1,
          "x-nullable": true
        },
        "send_report_every_x_days": {
          "title": "Send report every x days",
          "type": "integer",
          "enum": [
            7,
            14
          ],
          "readOnly": true,
          "x-nullable": true
        },
        "report_day_of_week": {
          "title": "Report day of week",
          "type": "integer",
          "enum": [
            0,
            1,
            2,
            3,
            4,
            5,
            6
          ],
          "readOnly": true,
          "x-nullable": true
        },
        "banner": {
          "$ref": "#/definitions/ManagerNotificationBanner"
        },
        "report_email": {
          "$ref": "#/definitions/ManagerReportEmail"
        }
      }
    },
    "CampaignDetailsResponse": {
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "name": {
          "title": "Name",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "flow_type": {
          "title": "Flow type",
          "description": "Campaign Flow Type:\n- `1` = Training Only - Campaign that only includes training content\n- `2` = Simulation and Training - Campaign that includes both phishing simulation and training",
          "type": "string",
          "enum": [
            1,
            2
          ],
          "readOnly": true
        },
        "status": {
          "title": "Status",
          "description": "Campaign Status:\n- `0` = Draft - Campaign is in draft state and not yet active\n- `1` = Collecting (Active) - Campaign is actively collecting participant data\n- `2` = Completed - Campaign has finished and is closed\n- `3` = Pending - Campaign is approved but waiting to start\n- `4` = Active - Campaign is currently running and sending emails\n- `5` = Inactive - Campaign is inactive",
          "type": "string",
          "enum": [
            0,
            1,
            2,
            3,
            4,
            5
          ],
          "readOnly": true
        },
        "schedule_time": {
          "title": "Schedule time",
          "type": "string",
          "format": "date-time",
          "readOnly": true
        },
        "end_time": {
          "title": "End time",
          "type": "string",
          "format": "date-time",
          "readOnly": true
        },
        "close_time": {
          "title": "Close time",
          "type": "string",
          "format": "date-time",
          "readOnly": true
        },
        "default_locale_id": {
          "title": "Default locale id",
          "type": "integer",
          "readOnly": true
        },
        "timezone": {
          "title": "Timezone",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "participants_count": {
          "title": "Participants count",
          "type": "integer",
          "readOnly": true
        },
        "company_id": {
          "title": "Company id",
          "type": "string",
          "readOnly": true
        },
        "participants_choices": {
          "title": "Participants choices",
          "type": "object",
          "readOnly": true,
          "x-nullable": true
        },
        "participants_exclude_choices": {
          "title": "Participants exclude choices",
          "type": "object",
          "readOnly": true,
          "x-nullable": true
        },
        "delivery_type": {
          "title": "Delivery type",
          "description": "Campaign Delivery Type:\n- `0` = Email - Campaign is delivered via email\n- `1` = SMS - Campaign is delivered via SMS",
          "type": "integer",
          "readOnly": true
        },
        "randomized": {
          "title": "Randomized",
          "description": "Send Emails to participants at random times",
          "type": "boolean",
          "readOnly": true
        },
        "randomized_scenarios": {
          "title": "Randomized scenarios",
          "type": "boolean",
          "readOnly": true
        },
        "max_email_per_day": {
          "title": "Max email per day",
          "type": "integer",
          "readOnly": true,
          "minimum": 1
        },
        "send_all_week": {
          "title": "Send all week",
          "type": "boolean",
          "readOnly": true
        },
        "send_reminders_until": {
          "title": "Send reminders until",
          "type": "string",
          "format": "date-time",
          "readOnly": true,
          "x-nullable": true
        },
        "send_reminder_every_x_business_days": {
          "title": "Send reminder every x business days",
          "type": "integer",
          "readOnly": true,
          "minimum": 1,
          "x-nullable": true
        },
        "max_reminders_per_participant": {
          "title": "Max reminders per participant",
          "type": "integer",
          "readOnly": true,
          "minimum": 1,
          "x-nullable": true
        },
        "locales_by_profiles": {
          "title": "Locales by profiles",
          "type": "boolean",
          "readOnly": true
        },
        "locale_ids": {
          "type": "array",
          "items": {
            "type": "integer"
          },
          "readOnly": true,
          "uniqueItems": true
        },
        "send_campaign_summary_to_campaign_report_recipients": {
          "title": "Send campaign summary to campaign report recipients",
          "type": "boolean",
          "readOnly": true
        },
        "send_completion_email": {
          "title": "Send completion email",
          "type": "boolean",
          "readOnly": true
        },
        "send_campaign_failed_email": {
          "title": "Send campaign failed email",
          "type": "boolean",
          "readOnly": true,
          "x-nullable": true
        },
        "landing_page": {
          "$ref": "#/definitions/LandingPage"
        },
        "segments": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/Segment"
          },
          "readOnly": true
        },
        "scenarios": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/Scenario"
          },
          "readOnly": true
        },
        "training_campaign_data": {
          "$ref": "#/definitions/TrainingCampaignData"
        },
        "training_reminders": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/TrainingReminderContent"
          },
          "readOnly": true
        },
        "notifications": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/CampaignNotification"
          },
          "readOnly": true
        },
        "trainings": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/CampaignTrainingContent"
          },
          "readOnly": true
        },
        "manager_notification_settings": {
          "$ref": "#/definitions/CampaignManagerNotificationSettings"
        }
      }
    },
    "CallForActionData": {
      "description": "List of call for action pages for the current page",
      "required": [
        "id",
        "name",
        "page_title",
        "content",
        "is_system",
        "is_public",
        "last_updated",
        "company_id"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "description": "Unique identifier for the call for action page",
          "type": "integer"
        },
        "name": {
          "title": "Name",
          "description": "Name of the call for action page",
          "type": "string",
          "minLength": 1
        },
        "page_title": {
          "title": "Page title",
          "description": "Title of the call for action page",
          "type": "string",
          "x-nullable": true
        },
        "content": {
          "title": "Content",
          "description": "HTML content of the call for action page",
          "type": "string",
          "x-nullable": true
        },
        "is_system": {
          "title": "Is system",
          "description": "Whether the call for action page is a system page",
          "type": "boolean"
        },
        "is_public": {
          "title": "Is public",
          "description": "Whether the call for action page is public",
          "type": "boolean"
        },
        "last_updated": {
          "title": "Last updated",
          "description": "Date and time when the call for action page was last updated",
          "type": "string",
          "format": "date-time"
        },
        "tags": {
          "title": "Tags",
          "description": "Tags indicating the origin of the call for action page (System, Company, or Partner)",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "company_id": {
          "title": "Company id",
          "description": "ID of the company that owns this call for action page (null for system pages)",
          "type": "integer",
          "x-nullable": true
        }
      }
    },
    "CallForAction": {
      "required": [
        "page",
        "total_pages",
        "total_count",
        "data"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "description": "Current page number",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "description": "Total number of pages",
          "type": "integer"
        },
        "total_count": {
          "title": "Total count",
          "description": "Total number of call for action pages matching the query",
          "type": "integer"
        },
        "data": {
          "description": "List of call for action pages for the current page",
          "type": "array",
          "items": {
            "$ref": "#/definitions/CallForActionData"
          }
        }
      }
    },
    "LandingPageContent": {
      "type": "object",
      "properties": {
        "content": {
          "title": "Content",
          "type": "string",
          "x-nullable": true
        },
        "page_title": {
          "title": "Page title",
          "type": "string",
          "maxLength": 100,
          "x-nullable": true
        },
        "locale_id": {
          "title": "Locale id",
          "type": "string",
          "readOnly": true
        }
      }
    },
    "LandingPagesData": {
      "required": [
        "id",
        "name",
        "is_system",
        "last_updated",
        "training_type",
        "contents"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "type": "integer"
        },
        "name": {
          "title": "Name",
          "type": "string",
          "minLength": 1
        },
        "tags": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "readOnly": true
        },
        "is_system": {
          "title": "Is system",
          "type": "boolean"
        },
        "last_updated": {
          "title": "Last updated",
          "type": "string",
          "format": "date-time"
        },
        "training_type": {
          "title": "Training type",
          "type": "integer"
        },
        "contents": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/LandingPageContent"
          }
        },
        "company_id": {
          "title": "Company id",
          "type": "string",
          "readOnly": true
        }
      }
    },
    "LandingPages": {
      "required": [
        "page",
        "total_pages",
        "total_count",
        "data"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "total_count": {
          "title": "Total count",
          "type": "integer"
        },
        "data": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/LandingPagesData"
          }
        }
      }
    },
    "ParticipantsListResponse": {
      "type": "object",
      "properties": {
        "all_company": {
          "title": "All company",
          "description": "Total count of all company participants",
          "type": "integer",
          "readOnly": true
        },
        "names": {
          "title": "Names",
          "description": "Dictionary of individual users with email and full name",
          "type": "object",
          "additionalProperties": {
            "description": "full_name and mail",
            "type": "object",
            "additionalProperties": {
              "type": "string",
              "minLength": 1
            }
          },
          "readOnly": true
        },
        "departments": {
          "title": "Departments",
          "description": "Dictionary of departments with participant counts",
          "type": "object",
          "additionalProperties": {
            "type": "integer"
          },
          "readOnly": true
        },
        "cities": {
          "title": "Cities",
          "description": "Dictionary of cities with participant counts",
          "type": "object",
          "additionalProperties": {
            "type": "integer"
          },
          "readOnly": true
        },
        "countries": {
          "title": "Countries",
          "description": "Dictionary of countries with participant counts",
          "type": "object",
          "additionalProperties": {
            "type": "integer"
          },
          "readOnly": true
        },
        "titles": {
          "title": "Titles",
          "description": "Dictionary of job titles with participant counts",
          "type": "object",
          "additionalProperties": {
            "type": "integer"
          },
          "readOnly": true
        },
        "tags": {
          "title": "Tags",
          "description": "Dictionary of tags with participant counts",
          "type": "object",
          "additionalProperties": {
            "type": "integer"
          },
          "readOnly": true
        },
        "featured_groups": {
          "title": "Featured groups",
          "description": "Dictionary of featured groups with participant counts",
          "type": "object",
          "additionalProperties": {
            "type": "integer"
          },
          "readOnly": true
        },
        "segments": {
          "title": "Segments",
          "description": "Dictionary of segments with participant counts",
          "type": "object",
          "additionalProperties": {
            "type": "integer"
          },
          "readOnly": true
        },
        "awareness_levels": {
          "title": "Awareness levels",
          "description": "Dictionary of awareness levels with participant counts",
          "type": "object",
          "additionalProperties": {
            "type": "integer"
          },
          "readOnly": true
        }
      }
    },
    "ParticipantsCalculateRequest": {
      "required": [
        "include"
      ],
      "type": "object",
      "properties": {
        "include": {
          "$ref": "#/definitions/ParticipantsCalculateInclude"
        },
        "exclude": {
          "$ref": "#/definitions/ParticipantsCalculateBase"
        }
      }
    },
    "AwarenessLevelsDistribution": {
      "description": "Get awareness levels distribution.\n\n        Args:\n            content: Dictionary containing participants queryset.\n\n        Returns:\n            Dictionary with awareness level distribution (beginner, mid, expert).\n",
      "type": "object",
      "properties": {
        "beginner": {
          "title": "Beginner",
          "type": "integer",
          "readOnly": true
        },
        "mid": {
          "title": "Mid",
          "type": "integer",
          "readOnly": true
        },
        "expert": {
          "title": "Expert",
          "type": "integer",
          "readOnly": true
        }
      }
    },
    "ParticipantsCalculateResponseMeta": {
      "description": "Get metadata for the response.\n\n        Args:\n            content: Dictionary containing participants data and queryset.\n\n        Returns:\n            Dictionary containing metadata (count, locale_ids, awareness_levels).\n",
      "required": [
        "count"
      ],
      "type": "object",
      "properties": {
        "count": {
          "title": "Count",
          "type": "integer"
        },
        "locale_ids": {
          "description": "Get list of distinct locale IDs from participants.\n\n        Args:\n            content: Dictionary containing participants queryset.\n\n        Returns:\n            List of distinct locale IDs from participants.\n",
          "type": "array",
          "items": {
            "type": "integer"
          },
          "readOnly": true
        },
        "awareness_levels": {
          "$ref": "#/definitions/AwarenessLevelsDistribution"
        }
      }
    },
    "ParticipantCandidate": {
      "required": [
        "id",
        "first_name",
        "last_name",
        "email"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "type": "integer"
        },
        "first_name": {
          "title": "First name",
          "type": "string",
          "minLength": 1
        },
        "last_name": {
          "title": "Last name",
          "type": "string",
          "minLength": 1
        },
        "email": {
          "title": "Email",
          "type": "string",
          "format": "email",
          "minLength": 1
        }
      }
    },
    "ParticipantsCalculateResponse": {
      "type": "object",
      "properties": {
        "meta": {
          "$ref": "#/definitions/ParticipantsCalculateResponseMeta"
        },
        "items": {
          "description": "Get list of participant candidates.",
          "type": "array",
          "items": {
            "$ref": "#/definitions/ParticipantCandidate"
          },
          "readOnly": true
        }
      }
    },
    "ParticipantsSearchRequest": {
      "required": [
        "search"
      ],
      "type": "object",
      "properties": {
        "search": {
          "title": "Search",
          "description": "Search string to filter participants.\n- Minimum 2 characters required for filtering\n- Case-insensitive substring match on names and emails",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "ParticipantItem": {
      "required": [
        "name",
        "tag"
      ],
      "type": "object",
      "properties": {
        "name": {
          "title": "Name",
          "description": "Display name of the participant or category item",
          "type": "string",
          "minLength": 1
        },
        "tag": {
          "title": "Tag",
          "description": "Category tag (e.g., 'Departments', 'Cities', 'Names')",
          "type": "string",
          "minLength": 1
        },
        "mail": {
          "title": "Mail",
          "description": "Email address (only present for 'Names' tag items)",
          "type": "string",
          "format": "email",
          "minLength": 1,
          "x-nullable": true
        }
      }
    },
    "ParticipantsSearchResponse": {
      "type": "object",
      "properties": {
        "items": {
          "description": "Flattened list of matching participant items",
          "type": "array",
          "items": {
            "$ref": "#/definitions/ParticipantItem"
          },
          "readOnly": true
        }
      }
    },
    "Language": {
      "required": [
        "id",
        "name",
        "short_name",
        "localized_name",
        "ltr",
        "enabled",
        "default"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "description": "Locale ID",
          "type": "integer"
        },
        "name": {
          "title": "Name",
          "description": "Locale name",
          "type": "string",
          "minLength": 1
        },
        "short_name": {
          "title": "Short name",
          "description": "Locale short name",
          "type": "string",
          "minLength": 1
        },
        "localized_name": {
          "title": "Localized name",
          "description": "Localized locale name",
          "type": "string",
          "minLength": 1
        },
        "ltr": {
          "title": "Ltr",
          "description": "Left-to-right text direction",
          "type": "boolean"
        },
        "enabled": {
          "title": "Enabled",
          "description": "Whether this locale is enabled for the company",
          "type": "boolean"
        },
        "default": {
          "title": "Default",
          "description": "Whether this is the default locale for the company",
          "type": "boolean"
        }
      }
    },
    "LocaleContent": {
      "required": [
        "body",
        "subject"
      ],
      "type": "object",
      "properties": {
        "body": {
          "title": "Body",
          "description": "Content body",
          "type": "string",
          "minLength": 1
        },
        "subject": {
          "title": "Subject",
          "description": "Content subject",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "LocaleBannerContent": {
      "required": [
        "text"
      ],
      "type": "object",
      "properties": {
        "text": {
          "title": "Text",
          "description": "Banner text content",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "CampaignSetup": {
      "type": "object",
      "properties": {
        "languages": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/Language"
          },
          "readOnly": true
        },
        "timezone": {
          "title": "Timezone",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "workdays": {
          "title": "Workdays",
          "description": "Workdays configuration: 1 - Monday-Friday, 2 - Sunday-Thursday, 3 - All Week",
          "type": "integer",
          "enum": [
            1,
            2,
            3
          ],
          "readOnly": true
        },
        "campaigns_limit_for_year": {
          "title": "Campaigns limit for year",
          "type": "integer",
          "readOnly": true,
          "x-nullable": true
        },
        "campaign_mails_limit": {
          "title": "Campaign mails limit",
          "type": "integer",
          "readOnly": true,
          "x-nullable": true
        },
        "allowed_senders_for_training_campaigns": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "readOnly": true
        },
        "manager_notification_state": {
          "title": "Manager notification state",
          "description": "Manager notification state: 1 - enabled, 2 - disabled, 3 - hidden",
          "type": "integer",
          "enum": [
            1,
            2,
            3
          ],
          "readOnly": true
        },
        "default_training_reminder_content_simulation": {
          "title": "Default training reminder content simulation",
          "type": "object",
          "additionalProperties": {
            "$ref": "#/definitions/LocaleContent"
          },
          "readOnly": true
        },
        "default_training_reminder_content_training": {
          "title": "Default training reminder content training",
          "type": "object",
          "additionalProperties": {
            "$ref": "#/definitions/LocaleContent"
          },
          "readOnly": true
        },
        "default_campaign_failed_alert_content": {
          "title": "Default campaign failed alert content",
          "type": "object",
          "additionalProperties": {
            "$ref": "#/definitions/LocaleContent"
          },
          "readOnly": true
        },
        "default_manager_notification_banner_content": {
          "title": "Default manager notification banner content",
          "type": "object",
          "additionalProperties": {
            "$ref": "#/definitions/LocaleBannerContent"
          },
          "readOnly": true
        },
        "default_manager_report_email_content": {
          "title": "Default manager report email content",
          "type": "object",
          "additionalProperties": {
            "$ref": "#/definitions/LocaleContent"
          },
          "readOnly": true
        }
      }
    },
    "TemplateContent": {
      "required": [
        "locale",
        "body",
        "landing_domain_id"
      ],
      "type": "object",
      "properties": {
        "locale": {
          "title": "Locale",
          "type": "integer"
        },
        "body_hint": {
          "title": "Body hint",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "body_link_hint": {
          "title": "Body link hint",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "body": {
          "title": "Body",
          "type": "string",
          "minLength": 1
        },
        "from_email": {
          "title": "From email",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "from_number": {
          "title": "From number",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "from_address_hint": {
          "title": "From address hint",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "subject": {
          "title": "Subject",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "subject_hint": {
          "title": "Subject hint",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "call_for_action_page_id": {
          "title": "Call for action page id",
          "type": "string",
          "readOnly": true
        },
        "landing_domain_id": {
          "title": "Landing domain id",
          "type": "integer",
          "x-nullable": true
        },
        "landing_subdomain": {
          "title": "Landing subdomain",
          "type": "string",
          "format": "slug",
          "pattern": "^[-a-zA-Z0-9_]+$",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "folder_name": {
          "title": "Folder name",
          "type": "string",
          "format": "slug",
          "pattern": "^[-a-zA-Z0-9_]+$",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "filename": {
          "title": "Filename",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "filetype": {
          "title": "Filetype",
          "type": "integer",
          "enum": [
            1,
            2,
            3,
            4
          ],
          "readOnly": true,
          "x-nullable": true
        },
        "attachment_hint": {
          "title": "Attachment hint",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "average_click_rate": {
          "title": "Average click rate",
          "type": "number",
          "readOnly": true
        },
        "average_reported_rate": {
          "title": "Average reported rate",
          "type": "number",
          "readOnly": true
        },
        "total_number_of_emails_sent": {
          "title": "Total number of emails sent",
          "type": "integer",
          "readOnly": true,
          "x-nullable": true
        }
      }
    },
    "Template": {
      "required": [
        "is_communityCandidate"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "name": {
          "title": "Name",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "last_updated": {
          "title": "Last updated",
          "type": "string",
          "format": "date-time",
          "readOnly": true
        },
        "same_company": {
          "title": "Same company",
          "type": "boolean",
          "readOnly": true
        },
        "is_system": {
          "title": "Is system",
          "type": "boolean",
          "readOnly": true
        },
        "is_community": {
          "title": "Is community",
          "type": "boolean",
          "readOnly": true
        },
        "is_communityCandidate": {
          "title": "Is communitycandidate",
          "type": "boolean"
        },
        "type": {
          "title": "Type",
          "type": "integer",
          "enum": [
            0,
            1,
            2,
            3,
            5
          ],
          "readOnly": true
        },
        "level": {
          "title": "Level",
          "type": "integer",
          "enum": [
            0,
            1,
            2
          ],
          "readOnly": true
        },
        "category": {
          "title": "Category",
          "type": "integer",
          "readOnly": true
        },
        "created_by": {
          "title": "Created by",
          "type": "integer",
          "readOnly": true
        },
        "name_for_partners": {
          "title": "Name for partners",
          "type": "string",
          "readOnly": true
        },
        "company_id": {
          "title": "Company id",
          "type": "string",
          "readOnly": true
        },
        "last_used": {
          "title": "Last used",
          "type": "string",
          "readOnly": true
        },
        "is_new": {
          "title": "Is new",
          "type": "boolean",
          "readOnly": true
        },
        "items": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/TemplateContent"
          },
          "readOnly": true
        }
      }
    },
    "TemplatesListResponse": {
      "required": [
        "page",
        "total_pages",
        "total_count",
        "data"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "total_count": {
          "title": "Total count",
          "type": "integer"
        },
        "data": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/Template"
          }
        }
      }
    },
    "TemplateCategory": {
      "required": [
        "id",
        "name"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "type": "integer"
        },
        "name": {
          "title": "Name",
          "type": "string",
          "minLength": 1
        }
      }
    },
    "TemplateCategoriesResponse": {
      "required": [
        "data"
      ],
      "type": "object",
      "properties": {
        "data": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/TemplateCategory"
          }
        }
      }
    },
    "TrainingItem": {
      "required": [
        "locale_id",
        "embedded_subtitles"
      ],
      "type": "object",
      "properties": {
        "locale_id": {
          "title": "Locale id",
          "type": "integer"
        },
        "image_preview": {
          "title": "Image preview",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "duration": {
          "title": "Duration",
          "type": "string",
          "readOnly": true,
          "minLength": 1,
          "x-nullable": true
        },
        "content": {
          "title": "Content",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "embedded_subtitles": {
          "title": "Embedded subtitles",
          "type": "boolean"
        }
      }
    },
    "Training": {
      "required": [
        "is_free",
        "is_new"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "ID",
          "type": "integer",
          "readOnly": true
        },
        "is_free": {
          "title": "Is free",
          "type": "boolean"
        },
        "is_new": {
          "title": "Is new",
          "type": "boolean"
        },
        "vendor": {
          "title": "Vendor",
          "type": "integer",
          "enum": [
            6,
            5,
            1,
            3,
            4
          ],
          "x-nullable": true
        },
        "name": {
          "title": "Name",
          "type": "string",
          "readOnly": true
        },
        "categories": {
          "type": "array",
          "items": {
            "type": "string",
            "minLength": 1
          },
          "readOnly": true
        },
        "has_permissions": {
          "title": "Has permissions",
          "type": "boolean",
          "readOnly": true
        },
        "season_info": {
          "title": "Season info",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "type": {
          "title": "Type",
          "type": "string",
          "readOnly": true,
          "minLength": 1
        },
        "items": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/TrainingItem"
          },
          "readOnly": true
        },
        "subtitles": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/BaseTrainingSubtitle"
          },
          "readOnly": true
        }
      }
    },
    "TrainingsListResponse": {
      "required": [
        "page",
        "total_pages",
        "total_count",
        "data"
      ],
      "type": "object",
      "properties": {
        "page": {
          "title": "Page",
          "type": "integer"
        },
        "total_pages": {
          "title": "Total pages",
          "type": "integer"
        },
        "total_count": {
          "title": "Total count",
          "type": "integer"
        },
        "data": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/Training"
          }
        }
      }
    },
    "TrainingProvider": {
      "required": [
        "id",
        "name",
        "total_count",
        "available_count"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "type": "integer"
        },
        "name": {
          "title": "Name",
          "type": "string",
          "minLength": 1
        },
        "total_count": {
          "title": "Total count",
          "type": "integer"
        },
        "available_count": {
          "title": "Available count",
          "type": "integer"
        }
      }
    },
    "TrainingProvidersResponse": {
      "required": [
        "data"
      ],
      "type": "object",
      "properties": {
        "data": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/TrainingProvider"
          }
        }
      }
    },
    "AccountTakeoverSettings": {
      "required": [
        "sensitivity"
      ],
      "type": "object",
      "properties": {
        "sensitivity": {
          "title": "Sensitivity",
          "description": "ATO sensitivity level: 1 (Aggressive), 2 (Balanced), 3 (Relaxed)",
          "type": "integer",
          "enum": [
            1,
            2,
            3
          ]
        }
      }
    },
    "WhiteListEntry": {
      "description": "List of allowed entries",
      "required": [
        "id",
        "date",
        "value",
        "type",
        "scope",
        "comment",
        "user_first_name",
        "user_last_name",
        "user_email",
        "external_campaigns",
        "ignore_auth"
      ],
      "type": "object",
      "properties": {
        "id": {
          "title": "Id",
          "description": "Unique identifier of the whitelist entry",
          "type": "integer"
        },
        "date": {
          "title": "Date",
          "description": "Date and time when the entry was created or modified",
          "type": "string",
          "format": "date-time"
        },
        "value": {
          "title": "Value",
          "description": "Value of the whitelist entry (domain, IP, email, etc.)",
          "type": "string",
          "minLength": 1
        },
        "type": {
          "title": "Type",
          "description": "Type of whitelist entry: 1 (IP Network), 2 (Domain), 3 (Sender Address), 4 (Unscanned Domain Link)",
          "type": "integer"
        },
        "scope": {
          "title": "Scope",
          "description": "Scope of the whitelist entry: 1=Skip All Inspections, 2=Bypass Impersonation Banners, 3=Bypass link clicking by IRONSCALES, 4=Spam Filter, 6=Bypass all scanning for links",
          "type": "integer",
          "maximum": 6,
          "minimum": 1
        },
        "comment": {
          "title": "Comment",
          "description": "Optional comment for the entry",
          "type": "string",
          "minLength": 1,
          "x-nullable": true
        },
        "user_first_name": {
          "title": "User first name",
          "description": "First name of the user who created the entry",
          "type": "string",
          "minLength": 1
        },
        "user_last_name": {
          "title": "User last name",
          "description": "Last name of the user who created the entry",
          "type": "string",
          "minLength": 1
        },
        "user_email": {
          "title": "User email",
          "description": "Email of the user who created the entry",
          "type": "string",
          "minLength": 1
        },
        "external_campaigns": {
          "title": "External campaigns",
          "description": "Whether this entry applies to external campaigns",
          "type": "boolean"
        },
        "ignore_auth": {
          "title": "Ignore auth",
          "description": "Whether authentication should be ignored for this entry",
          "type": "boolean"
        }
      }
    },
    "WhiteListResponse": {
      "required": [
        "allow_list",
        "internal_active",
        "external_active",
        "pages_count",
        "page",
        "items_per_page"
      ],
      "type": "object",
      "properties": {
        "allow_list": {
          "description": "List of allowed entries",
          "type": "array",
          "items": {
            "$ref": "#/definitions/WhiteListEntry"
          }
        },
        "internal_active": {
          "title": "Internal active",
          "description": "Whether internal whitelist is active",
          "type": "boolean"
        },
        "external_active": {
          "title": "External active",
          "description": "Whether external whitelist is active",
          "type": "boolean"
        },
        "pages_count": {
          "title": "Pages count",
          "description": "Total number of pages",
          "type": "integer"
        },
        "page": {
          "title": "Page",
          "description": "Current page number",
          "type": "integer"
        },
        "items_per_page": {
          "title": "Items per page",
          "description": "Number of items per page",
          "type": "integer"
        }
      }
    },
    "WhitelistAddRow": {
      "required": [
        "type",
        "value"
      ],
      "type": "object",
      "properties": {
        "type": {
          "title": "Type",
          "description": "Type of whitelist entry. Choices: 1=IP Network (for IP addresses or CIDR notation), 2=Domain (for domain names), 3=Sender Address (for email addresses), 4=Unscanned Domain Link (for domain names in links)",
          "type": "string",
          "enum": [
            1,
            2,
            3,
            4
          ]
        },
        "scope": {
          "title": "Scope",
          "description": "Scope of the whitelist entry: 1=Skip All Inspections, 2=Bypass Impersonation Banners, 3=Bypass link clicking by IRONSCALES, 4=Spam Filter, 6=Bypass all scanning for links",
          "type": "integer",
          "default": 1
        },
        "value": {
          "title": "Value",
          "description": "Value to whitelist. For type=1: provide IP address or CIDR notation (e.g., 192.168.1.1 or 10.0.0.0/24). For type=2: provide domain name (e.g., example.com). For type=3: provide email address (e.g., user@example.com). For type=4: provide domain name for unscanned links.",
          "type": "string",
          "minLength": 1
        },
        "comment": {
          "title": "Comment",
          "description": "Optional comment or description for this whitelist entry",
          "type": "string",
          "x-nullable": true
        },
        "external_campaigns": {
          "title": "External campaigns",
          "description": "When true, this whitelist entry will also apply to external campaigns",
          "type": "boolean",
          "default": false
        },
        "ignore_auth": {
          "title": "Ignore auth",
          "description": "When true, authentication will be ignored for this whitelist entry",
          "type": "boolean",
          "default": false
        }
      }
    },
    "WhitelistUpdateRow": {
      "required": [
        "type",
        "value",
        "selected_id"
      ],
      "type": "object",
      "properties": {
        "type": {
          "title": "Type",
          "description": "Type of whitelist entry. Choices: 1=IP Network (for IP addresses or CIDR notation), 2=Domain (for domain names), 3=Sender Address (for email addresses), 4=Unscanned Domain Link (for domain names in links)",
          "type": "string",
          "enum": [
            1,
            2,
            3,
            4
          ]
        },
        "scope": {
          "title": "Scope",
          "description": "Scope of the whitelist entry: 1=Skip All Inspections, 2=Bypass Impersonation Banners, 3=Bypass link clicking by IRONSCALES, 4=Spam Filter, 6=Bypass all scanning for links",
          "type": "integer",
          "default": 1
        },
        "value": {
          "title": "Value",
          "description": "Value to whitelist. For type=1: provide IP address or CIDR notation (e.g., 192.168.1.1 or 10.0.0.0/24). For type=2: provide domain name (e.g., example.com). For type=3: provide email address (e.g., user@example.com). For type=4: provide domain name for unscanned links.",
          "type": "string",
          "minLength": 1
        },
        "comment": {
          "title": "Comment",
          "description": "Optional comment or description for this whitelist entry",
          "type": "string",
          "x-nullable": true
        },
        "external_campaigns": {
          "title": "External campaigns",
          "description": "When true, this whitelist entry will also apply to external campaigns",
          "type": "boolean",
          "default": false
        },
        "ignore_auth": {
          "title": "Ignore auth",
          "description": "When true, authentication will be ignored for this whitelist entry",
          "type": "boolean",
          "default": false
        },
        "selected_id": {
          "title": "Selected id",
          "description": "ID of the existing allow list entry to update.",
          "type": "integer",
          "minimum": 1
        }
      }
    },
    "WhiteListDelete": {
      "required": [
        "selected_ids"
      ],
      "type": "object",
      "properties": {
        "selected_ids": {
          "description": "List of allow list entry IDs to delete",
          "type": "array",
          "items": {
            "type": "integer",
            "minimum": 1
          },
          "minItems": 1
        }
      }
    },
    "ChallengedSettings": {
      "required": [
        "recipients"
      ],
      "type": "object",
      "properties": {
        "recipients": {
          "type": "array",
          "items": {
            "type": "string",
            "format": "email",
            "minLength": 1
          }
        }
      }
    },
    "NotificationSettings": {
      "required": [
        "recipients"
      ],
      "type": "object",
      "properties": {
        "recipients": {
          "type": "array",
          "items": {
            "type": "string",
            "format": "email",
            "minLength": 1
          }
        }
      }
    }
  }
}