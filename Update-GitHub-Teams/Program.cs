/*
 * Save the Area Pods excel spreadsheet to a CSV file and format it as such:
 *
 * - First line is a list of GitHub usernames in the order of the team members' column headers
 * - Second line is blank
 * - All remaining lines represent GitHub areas with corresponding GitHub teams
 * - On each of those lines, the first column is the area name (which will be converted to a team name)
 * - Columns follow for each team member indicated on the first line
 * - Those columns have numeric values where "-1" means they are removed, "1" means they're added, and "0" means they are kept
 * - All other values are ignored and no action is taken; consultants and shared ownership are not acted upon
 * - Areas where we do not use a GitHub team should be removed; e.g. area-infrastructure
 *
 * The CSV from the area pod updates in Nov 2022 is saved here for reference.
 *
 * With the CSV ready, run this program passing the path to the CSV as the single argument. Redirect output to a cmd file
 * that can then be executed. The produced script uses the GitHub CLI to make the team membership changes.
 *
 * Former team members can also be specified below to be removed from all teams. Leads can be specified to be added to all teams.
 */

var csv = args[0];

var content = File.ReadAllLines(csv);
var members = content[0].Split(',');
var areas = content[2..];

var formerTeamMembers = new string[] { "maryamariyan", "Nick-Stanton" };
var leads = new string[] { "ericstj", "jeffhandley" };

foreach (var line in areas)
{
    var parts = line.Split(',');
    var areaTeam = parts[0].Replace('.', '-').ToLower();
    var assignments = parts[1..members.Length];

    foreach (var former in formerTeamMembers)
    {
        Console.WriteLine(Exclude(areaTeam, former));
    }

    foreach (var lead in leads)
    {
        Console.WriteLine(Include(areaTeam, lead));
    }

    for (var assignment = 0; assignment < assignments.Length; assignment++)
    {
        var update = assignments[assignment] switch
        {
            "0" or "1" => Include(areaTeam, members[assignment]),
            "-1" => Exclude(areaTeam, members[assignment]),
            _ => null,
        };

        if (update is not null)
        {
            Console.WriteLine(update);
        }
    }
}

static string Include(string areaTeam, string member) => $"gh api -X PUT /orgs/dotnet/teams/{areaTeam}/memberships/{member} -f role=\"maintainer\"";
static string Exclude(string areaTeam, string member) => $"gh api -X DELETE /orgs/dotnet/teams/{areaTeam}/memberships/{member}";
