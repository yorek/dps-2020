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
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;  
using System.Text;

namespace DPS2020.Controllers
{
    public class LoginInfo
    {
        public string Login { get; set; }
        public string Password { get; set; }
    }

    [ApiController]
    [Route("[controller]")]
    public class AuthorizationController : ControllerBase
    {
        private readonly IConfiguration _config;

        private readonly ILogger<AuthorizationController> _logger;

        public AuthorizationController(IConfiguration config, ILogger<AuthorizationController> logger)
        {
            _logger = logger;
            _config = config;
        }

        [AllowAnonymous]
        [HttpPost]        
        public IActionResult Post([FromBody]LoginInfo login)
        {
            string tokenString = string.Empty;

            if (login == null) 
                return Unauthorized();

            string userHashId = Authenticate(login);
            if (!string.IsNullOrEmpty(userHashId))
                tokenString = BuildToken(userHashId);
            else
                return Unauthorized();

            return Ok(tokenString);
        }

        private string BuildToken(string userHashId)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["JwtToken:SecretKey"]));
    
            var desc = new SecurityTokenDescriptor  
            {  
                Subject = new ClaimsIdentity(new[]  
                {  
                    new Claim(ClaimTypes.Sid, userHashId)
                }),  
                Expires = DateTime.UtcNow.AddMinutes(30),  
                SigningCredentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256Signature),
                Audience = _config["JwtToken:Issuer"],
                Issuer = _config["JwtToken:Issuer"]
            };  
  
            var handler = new JwtSecurityTokenHandler();  
            var token = handler.CreateToken(desc);  

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private string Authenticate(LoginInfo login)
        {
            // Simulate authentication done
            return "12345";
        }
    }    
}
