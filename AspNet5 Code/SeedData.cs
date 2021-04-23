using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using Application.Common.Models;
using Domain.Entities.Identity;
using Domain.Entities.Identity.Users;
using Infrastructure.Persistence.Seeds;
using Infrastructure.Resources;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Infrastructure.Persistence
{
    /// <summary>
    /// data seed container.
    /// </summary>
    public static class DatabaseMigrator
    {

        /// <summary>
        /// Seed execution of audit trail database;
        /// </summary>
        /// <param name="services"></param>
        /// <returns></returns>
        public static async Task ExecuteAuditDatabaseConfigurationsAsync(IServiceProvider services)
        {
            var context = services.GetRequiredService<"Your DBContext">();
            context.Database.SetCommandTimeout(0); //set timout for the queries to take time as much as the require (no timout error will be thrown)
            await context.Database.ExecuteSqlRawAsync(DatabaseResources.SP_GetTableDDL);
            await context.Database.ExecuteSqlRawAsync(DatabaseResources.SP_GenerateAuditDbTriggers);
            await context.Database.ExecuteSqlRawAsync(DatabaseResources.SmicaAuditDbCreationScript);
            await context.Database.ExecuteSqlRawAsync(DatabaseResources.SmicaAuditDbGenerationScript);
        }    
    }
}
