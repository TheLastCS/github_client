import 'package:flutter/material.dart';
import 'package:fluttericon/octicons_icons.dart';
import 'package:github/github.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GitHubSummary extends StatefulWidget {
  const GitHubSummary ({required this.gitHub, super.key});

  final GitHub gitHub;

  @override
  State<GitHubSummary> createState() => _GitHubSummaryState();
}

class _GitHubSummaryState extends State<GitHubSummary> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          labelType: NavigationRailLabelType.selected,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Octicons.repo),
              label: Text('Repositories'),
            ),
            NavigationRailDestination(
              icon: Icon(Octicons.issue_opened),
              label: Text('Assigned Issues'),
            ),
            NavigationRailDestination(
              icon: Icon(Octicons.git_pull_request),
              label: Text('Pull Requests'),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),

        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              RepositoriesList(gitHub: widget.gitHub),
              AssignedIssuesList(gitHub: widget.gitHub),
              PullRequestList(gitHub: widget.gitHub),
            ],
          ),
        )
      ],
    );
  }
}

class RepositoriesList extends StatefulWidget {
  const RepositoriesList({required this.gitHub, super.key});
  final GitHub gitHub;

  @override
  State<RepositoriesList> createState() => _RepositoriesListState();
}

class _RepositoriesListState extends State<RepositoriesList> {
  @override
  initState() {
    // TODO: implement initState
    super.initState();
    _repositories = widget.gitHub.repositories.listRepositories().toList();
  }

  late Future<List<Repository>> _repositories;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Repository>>(
      future: _repositories,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var repositories = snapshot.data;
        return ListView.builder(
          primary: false,
          itemBuilder:(context, index) {
            var repository = repositories![index];
            return ListTile(
              title: Text('${repository.owner?.login ?? ''}/${repository.name}'),
              subtitle: Text(repository.description),
              onTap:() => _launchUrl(context, repository.htmlUrl),
            );
          },
          itemCount: repositories!.length,
        );
      }
    );
  }
}

class AssignedIssuesList extends StatefulWidget {
  const AssignedIssuesList({required this.gitHub, super.key});
  final GitHub gitHub;

  @override
  State<AssignedIssuesList> createState() => _AssignedIssuesListState();
}

class _AssignedIssuesListState extends State<AssignedIssuesList> {
  @override
  initState() {
    // TODO: implement initState
    super.initState();
    _assignedIssues = widget.gitHub.issues.listByUser().toList();
  }

  late Future<List<Issue>> _assignedIssues;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Issue>>(
      future: _assignedIssues,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var assignedIssues = snapshot.data;
        return ListView.builder(
          primary: false,
          itemBuilder: (context, index) {
            var assignedIssue = assignedIssues![index];
            return ListTile(
              title: Text(assignedIssue.title),
              subtitle: Text('${_nameWithOwner(assignedIssue)} '
                              'Issue #${assignedIssue.number} '
                              'opened by ${assignedIssue.user?.login ?? ''}'),
              onTap: () => _launchUrl(context, assignedIssue.htmlUrl),
            );
          },
          itemCount: assignedIssues!.length,
        );
      },
    );
  }
}

String _nameWithOwner(Issue assignedIssue) {
  final endIndex = assignedIssue.url.lastIndexOf('/issues/');
  return assignedIssue.url.substring(29, endIndex);
}

Future<void> _launchUrl(BuildContext context, String url) async {
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url);
  } else {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Navigation error'),
        content: Text('Could not launch $url'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}