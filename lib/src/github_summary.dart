import 'package:flutter/material.dart';
import 'package:flutter_cms/src/repo_detail.dart';
import 'package:github/github.dart';

class GitHubSummary extends StatefulWidget {
  const GitHubSummary({required this.gitHub, super.key});
  final GitHub gitHub;

  @override
  State<GitHubSummary> createState() => _GitHubSummaryState();
}

class _GitHubSummaryState extends State<GitHubSummary> {
  @override
  Widget build(BuildContext context) {
    return RepositoriesList(gitHub: widget.gitHub);
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
    super.initState();
    _repositories = widget.gitHub.repositories.listRepositories().toList();
  }

  int _selectedIndex = 0;

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
        var repositories = snapshot.data ?? [];
        return Row(
          children: [
            LayoutBuilder(builder: (context, constraint) {
              return SingleChildScrollView(
                  child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraint.maxHeight),
                      child: IntrinsicHeight(
                          child: NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        labelType: NavigationRailLabelType.all,
                        destinations: repositories.map((Repository repo) {
                          return NavigationRailDestination(
                            icon: const Icon(Icons.pageview),
                            label: Text(repo.name),
                          );
                        }).toList(),
                      ))));
            }),

            const VerticalDivider(thickness: 1, width: 1),
            // This is the main content.
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: repositories.map((Repository repo) {
                  return RepoDetail(
                    gitHub: widget.gitHub,
                    repository: repo,
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
