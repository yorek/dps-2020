using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Text.Json;
using System.Security.Claims;  
using System.Data;
using Microsoft.Data.SqlClient;
using Dapper;

namespace DPS2020.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ToDoController : ControllerBase
    {
        private readonly ILogger<ToDoController> _logger;
        private readonly IConfiguration _config;

        public ToDoController(IConfiguration config, ILogger<ToDoController> logger)
        {
            _logger = logger;
            _config = config;
        }

        //[Authorize]
        [HttpGet]
        [Route("{id?}")]
        public async Task<JsonElement> Get(int? id)
        {
            using(var conn = new SqlConnection(_config.GetConnectionString("AzureSQL")))
            {
                var qp = new DynamicParameters();
                                            
                if (id.HasValue) {
                    var p = new {
                        id = id.Value
                    };

                    qp.Add("payload", JsonSerializer.Serialize(p));
                }
                
                var userHashId = GetUserHashId();

                await conn.OpenAsync();
                //await conn.ExecuteAsync("sys.sp_set_session_context", new { @key = "user-hash-id", @value = userHashId, @read_only = 1 }, commandType: CommandType.StoredProcedure );
                var qr = await conn.QuerySingleOrDefaultAsync<string>("web.get_todo", qp, commandType: CommandType.StoredProcedure);
                conn.Close();

                return ProcessResult(qr, returnArray: !id.HasValue);
            }            
        }

        [HttpPost]
        public async Task<JsonElement> Post([FromBody]JsonElement payload)
        {
            using(var conn = new SqlConnection(_config.GetConnectionString("AzureSQL")))
            {
                var qp = new DynamicParameters();
                qp.Add("payload", payload.ToString());

                var qr = await conn.QuerySingleOrDefaultAsync<string>("web.post_todo", qp, commandType: CommandType.StoredProcedure);

                return ProcessResult(qr, returnArray: false);
            }            
        }

        [HttpDelete]
        [Route("{id?}")]
        public async Task<JsonElement> Delete(int? id)
        {
            using(var conn = new SqlConnection(_config.GetConnectionString("AzureSQL")))
            {
                var qp = new DynamicParameters();
                if (id.HasValue) {
                    var p = new {
                        id = id.Value
                    };

                    qp.Add("payload", JsonSerializer.Serialize(p));
                }

                var qr = await conn.QuerySingleOrDefaultAsync<string>("web.delete_todo", qp, commandType: CommandType.StoredProcedure);

                return ProcessResult(qr);
            }            
        }

        [HttpPatch]
        [Route("{id}")]
        public async Task<JsonElement> Patch(int id, [FromBody]JsonElement patch)
        {
            using(var conn = new SqlConnection(_config.GetConnectionString("AzureSQL")))
            {
                var qp = new DynamicParameters();
                var p = new {
                    id = id,
                    todo = patch
                };
                qp.Add("payload", JsonSerializer.Serialize(p));

                var qr = await conn.QuerySingleOrDefaultAsync<string>("web.patch_todo", qp, commandType: CommandType.StoredProcedure);

                return ProcessResult(qr, returnArray: false);
            }            
        }

        private JsonElement ProcessResult(string source, bool returnArray = true)
        {
            var l = JsonSerializer.Deserialize<List<Dictionary<string, object>>>(source ?? "[]");
            
            foreach(var d in l)
            {
                d["url"] = HttpContext.Request.Scheme + "://" + HttpContext.Request.Host + "/todo/" + d["id"];
            }

            var j = JsonSerializer.Serialize(l);
            var r = JsonDocument.Parse(j).RootElement;
            
            if (returnArray == true) 
                return r; 
            
            if (r.EnumerateArray().Count() == 1)
                return r[0];
            else
                return r;
        }

        private async Task<int> GetUserHashId() {
            var accessToken = await HttpContext.GetTokenAsync("access_token");

            var handler = new JwtSecurityTokenHandler();
            var token = handler.ReadToken(accessToken) as JwtSecurityToken;
            var uid = token.Claims.First(claim => claim.Type == ClaimTypes.Sid).Value;

            return Int32.Parse(uid);
        }
    }
}
