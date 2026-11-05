import type { ErrorInfo, ReactNode } from 'react';
import { Component } from 'react';

interface Proprietes {
  readonly children: ReactNode;
}

interface Etat {
  readonly erreur: boolean;
}

export class BarriereErreur extends Component<Proprietes, Etat> {
  override state: Etat = { erreur: false };

  static getDerivedStateFromError(): Etat {
    return { erreur: true };
  }

  override componentDidCatch(erreur: Error, info: ErrorInfo): void {
    console.error('roulette :', erreur, info.componentStack);
  }

  override render(): ReactNode {
    return this.state.erreur ? null : this.props.children;
  }
}
