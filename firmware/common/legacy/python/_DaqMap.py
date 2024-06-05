import pyrogue as pr

class DaqMap(pr.Device):
    def __init__(self, febs, dataDpms, **kwargs):
        super().__init__(**kwargs)

        deps = []

        for i, dpm in dataDpms.items():
            for j, path in dpm.RceCore.DataPath.items():
                deps.append(path.FebNum)
                deps.append(path.HybridNum)

        def findDpm(febNum, hybridNum):
            def func():
                for i, dpm in dataDpms.items():
                    for j, path in dpm.RceCore.DataPath.items():
                        if (path.FebNum.value() == febNum and path.HybridNum.value() == hybridNum):
                            return f'DataDpm[{i}]Path[{j}]'
                return 'NotFound'
            return func


        for feb in febs.keys():
            for hybrid in range(4):
                self.add(pr.LinkVariable(
                    name = f'Feb[{feb}]Hybrid[{hybrid}]',
                    mode = 'RO',
                    dependencies = deps,
                    linkedGet = findDpm(feb, hybrid)))

        def findFeb(febNum, hybridNum):
            def func():
                if febNum.value() == 15:
                    return 'No Connection'
                else:
                    return f'Feb[{febNum.value()}]Hybrid[{hybridNum.value()}]'
            return func

        for i, dpm in dataDpms.items():
            for j, path in dpm.RceCore.DataPath.items():
                self.add(pr.LinkVariable(
                    name = f'DataDpm[{i}]Path[{j}]',
                    mode = 'RO',
                    dependencies = [path.FebNum, path.HybridNum],
                    linkedGet = findFeb(path.FebNum, path.HybridNum)))
